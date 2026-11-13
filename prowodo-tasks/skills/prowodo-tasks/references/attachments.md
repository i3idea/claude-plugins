# Attachments — company/project and task

← [Skill index](../SKILL.md) · See also: [comments](comments.md) · [notes](notes.md)

Files, text and links attached to companies, projects and tasks.

**When needed:** show what is attached to a project or a company, or create new
attachments (text, small files, links to Drive/Figma/web pages).

Two distinct families, not interchangeable:

- **Company/project attachments** — `list_attachments` / `retrieve_attachments` /
  `create_attachments` / `destroy_attachments` (path: `company_id`). `list_attachments`
  with `project_id` filters on one project, with `project_id__isnull=true` it shows only
  the company's attachments. **An attachment without a project (`project_id` omitted) has
  `app_url = null`: there is no "company attachments" page**, only the per-project one —
  do not expect a clickable link in that case, and say so if the user asks. There is no
  `update`/`partial_update_attachments`: an attachment is replaced (delete + recreate),
  not edited.
- **Task attachments** — `list_taskattachments` / `retrieve_taskattachments` (path:
  `task_id`), plus `request_taskattachment_upload` to create one via the two-step flow
  described further below (no `comment_id` field to pass: a container `TaskComment` is
  created automatically, as the upload from the app already does).

**Creating a company/project attachment** — `create_attachments` accepts exactly
ONE of:
- `text` — saved as a text/markdown file (requires `file_name`)
- `content_base64` — base64 binary (requires `file_name` and `content_type`)
- `link` — an http(s) URL, e.g. Google Drive/Figma/a web page (no file_name)

Inline content (`text`/`content_base64`) is **capped at 4 MB** — beyond that, upload to
Drive and pass the URL as `link`. Allowed file types: images, PDF, plain text, CSV,
Office documents and zip.

```
# text note on a project
create_attachments(company_id=1, body={
  "project_id": 7,
  "text": "## Decision\nWe use Resend for transactional emails.",
  "file_name": "decisione-mail-provider.md"
})

# link to a Drive file
create_attachments(company_id=1, body={
  "project_id": 7,
  "link": "https://drive.google.com/file/d/..."
})
```

**Larger or heavier files (beyond what is convenient to pass as `text`/`content_base64`)** —
use the two-step flow instead of `create_attachments`:

1. `request_attachment_upload(company_id, project_id?, title?)` — no file content
   in this call. It responds with `upload_url`, `method`, `file_field`,
   `expires_at`, `max_bytes`, `allowed_content_types`.
2. Make a multipart POST to `upload_url` with the file in the field named by
   `file_field` — with whatever HTTP client you have available in your
   environment (no specific command is prescribed: the response from step 1
   tells you what to send, not how). The token in `upload_url` expires after
   a few minutes and is single-use; if the file is rejected (type/size)
   it stays valid — retry with a different file without redoing step 1.
3. The response to that POST is the created attachment, with `app_url` included.

Same flow, same response shape, for attachments on **task comments**
(not on ticket comments, which stay out of scope — see [collaboration.md](collaboration.md)):
`request_taskattachment_upload(task_id)` → multipart POST → `TaskAttachment`
created, with an auto-generated container `TaskComment` as the upload
from the app already does.
