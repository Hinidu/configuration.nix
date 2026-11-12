# The cron jobs a session has now, restored from its transcript (the lines
# mentioning Cron, slurped): the daemon keeps them only in the session's
# memory. A job is active if it was created, not deleted, and is still due:
# a one-shot one deletes itself after it fires, a recurring one expires after
# 7 days. $utcOffsetSeconds is the local time zone offset: CronCreate reports
# the next run in local time.

def recurringLifetimeSeconds: 7 * 86400;

def toolCalls($name):
  .[] | select(.type == "assistant") | .message.content[]?
  | select(.type == "tool_use" and .name == $name);

def resultText:
  .content | if type == "string" then . else map(.text? // empty) | join("") end;

# "Nov 13 6:43am" of a job created at $createdAt, as epoch seconds
def nextRunSeconds($createdAt):
  ($createdAt | .[0:4]) as $year
  | ("\($year) \(.)" | strptime("%Y %b %d %I:%M%p") | mktime) - $utcOffsetSeconds
  | if . < ($createdAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) - 86400
    then . + 365 * 86400 else . end;

([toolCalls("CronCreate") | {key: .id, value: .input}] | from_entries) as $createCalls
| [toolCalls("CronDelete") | .input.id] as $deletedIds
| [ .[] | select(.type == "user") | .timestamp as $createdAt
    | .message.content[]?
    | select(.type == "tool_result" and $createCalls[.tool_use_id] != null)
    | $createCalls[.tool_use_id] as $call
    | resultText
    | capture("^Scheduled (?<kind>recurring job|one-shot task) (?<id>[0-9a-f]+) \\((?<schedule>[^)]*)\\)\\. Next run: (?<nextRun>[^.]+?)\\. ")?
    | { id, recurring: (.kind == "recurring job"), schedule, prompt: $call.prompt,
        createdAt: $createdAt, nextRunAt: (.nextRun | nextRunSeconds($createdAt)) } ]
| unique_by(.id)
| map(select(.id as $id | $deletedIds | index($id) | not))
| map(select(
    if .recurring
    then now - (.createdAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) < recurringLifetimeSeconds
    else .nextRunAt > now
    end))
