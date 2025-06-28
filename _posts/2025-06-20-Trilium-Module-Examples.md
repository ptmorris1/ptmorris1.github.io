---
title: Trilium PowerShell Module Examples
date: 2025-06-29 10:04:20 -0500
categories: [documentation]
tags: [powershell,windows,trilium,notes]
---

# TriliumPwsh PowerShell Module Examples


## About Trilium and the Trilium PowerShell Module

[Trilium Notes](https://github.com/TriliumNext/trilium) is a hierarchical note-taking application focused on building large personal knowledge bases. The Trilium PowerShell Module lets you automate, manage, and interact with your Trilium instance directly from PowerShell, making it easy to script note creation, updates, searches, and more.

### 🚀 Installation

Install the Trilium PowerShell module from the PowerShell Gallery:

```powershell
Install-Module Trilium -Scope CurrentUser
```

## Full Examples with Explanations

> [!IMPORTANT]
> You must authenticate first using `Connect-TriliumAuth` before using the rest of this module.

### 🔑 Connect-TriliumAuth

The `Connect-TriliumAuth` cmdlet is used to authenticate to a TriliumNext instance for API calls. It supports both password-based and ETAPI token authentication, and can optionally skip SSL certificate checks for self-signed certificates.

**Parameters:**
- `-BaseUrl` (String, Required): The base URL for your TriliumNext instance. Example: `https://trilium.myDomain.net`
- `-Password` (PSCredential): Credential object for password-based authentication.
- `-EtapiToken` (PSCredential): Credential object for ETAPI token authentication (token as password).
- `-SkipCertCheck` (Switch): Ignore SSL certificate errors (useful for self-signed certs).

> [!CAUTION]
> Credentials are stored in `$Global:TriliumCreds` for use by other module functions.

### 🔐 Authenticate with Password

Authenticate using your Trilium username and password:

> [!NOTE]
> Since Trilium doesn't need a username, anything will do.

```powershell
$creds = Get-Credential -UserName 'admin'
Connect-TriliumAuth -BaseUrl "https://trilium.myDomain.net" -Password $creds
```

> **Tip:** This output confirms successful connection and shows server environment details.

### 🔐 Authenticate with ETAPI Token

Authenticate using your ETAPI token (enter token as password):

> [!NOTE]
> Since Trilium doesn't need a username, anything will do.

```powershell
$token = Get-Credential -UserName 'admin' # Enter your ETAPI token as the password
Connect-TriliumAuth -BaseUrl "https://trilium.myDomain.net" -EtapiToken $token
```

### ⚠️ Skip Certificate Check (Self-Signed Certs)

If your Trilium instance uses a self-signed certificate, you can skip certificate validation:

```powershell
Connect-TriliumAuth -BaseUrl "https://trilium.myDomain.net" -Password $creds -SkipCertCheck
```

> [!TIP]
> All Trilium module cmdlets support the `-SkipCertCheck` parameter for self-signed certificates.

> [!NOTE]
> Ensure your BaseUrl is correct and accessible. Use `-SkipCertCheck` only if you trust the server.

### 🔌 Disconnect-TriliumAuth

Removes your session from Trilium and clears the global credential variable. If you authenticated with a password, it logs you out of Trilium. If you used an ETAPI token, it only clears the session variable.

**Parameters:**
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
None. This cmdlet performs a logout operation and clears credentials.

**Examples:**
```powershell
Disconnect-TriliumAuth
```
Logs out and clears credentials.

> [!NOTE]
> Use this cmdlet to ensure your credentials are cleared from your session, especially if you switch users or finish your automation tasks.

---

### 📝 New-TriliumNote

Creates a new note in Trilium with specified content, title, and options.

**Parameters:**
- `-Title` (String, Required): The title of the new note.
- `-Content` (String, Optional): The content of the new note.
- `-ParentNoteId` (String, Optional): The parent note ID (default: root).
- `-NoteType` (String, Optional): The type of note (e.g., text, code, markdown).
- `-Mime` (String, Optional): The MIME type of the note content.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).
- `-Markdown` (Switch, Optional): Convert markdown to HTML before sending.
- `-Math` (Switch, Optional): Enable MathJax for mathematical expressions.

**Supported NoteType values:**

- image
- file
- text
- book
- canvas
- mermaid
- geoMap
- mindMap
- relationMap
- renderNote
- webview
- PlainText
- CSS
- html
- http
- JSbackend
- JSfrontend
- json
- markdown
- powershell
- python
- ruby
- shellBash
- sql
- sqliteTrilium
- xml
- yaml

**Output:**  
Returns the new note object.

**Examples:**
```powershell
New-TriliumNote -Title "New Note" -Content "Hello World" -ParentNoteId "root"
```
Creates a new note under the root.

```powershell
New-TriliumNote -Title "Math Note" -Content '$a^2 + b^2 = c^2$' -Markdown -Math
```
Creates a new note with math rendering enabled.

```powershell
New-TriliumNote -Title "Markdown Note" -Content '# My Markdown Note`nThis is **bold** and this is *italic*.' -Markdown
```
Creates a new note from markdown content (without math).

> [!NOTE]
> When using the `-Markdown` switch, the `-Content` parameter should be raw markdown text. The function will handle the conversion to HTML automatically.

---

### 🖼️ Format-TriliumHtml

Formats and beautifies HTML content for Trilium Notes, fixing spacing, header formatting, and cleaning up HTML structure for best display in Trilium.

**Parameters:**
- `-Content` (String, Required): The HTML content to beautify.

**Output:**  
Returns a string with the beautified HTML content.

**Examples:**
```powershell
Format-TriliumHtml -Content "<h2>Header</h2><p>Text</p>"
```

```powershell
$markdownHtml = [Markdig.Markdown]::ToHtml($markdown)
Format-TriliumHtml -Content $markdownHtml
```

> [!TIP]
> Use this before sending HTML to Trilium to ensure best appearance.

---

### 📎 Get-TriliumAttachment

Retrieves metadata for a specific TriliumNext attachment by its ID.

**Parameters:**
- `-AttachmentID` (String, Required): The attachment ID to retrieve.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the attachment metadata as a PowerShell object.

**Examples:**
```powershell
Get-TriliumAttachment -AttachmentID "evnnmvHTCgIn"
```

---

### 📥 Get-TriliumAttachmentContent

Downloads the content of a TriliumNext attachment by its ID.

**Parameters:**
- `-AttachmentID` (String, Required): The attachment ID to retrieve content for.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the raw content of the attachment.

**Examples:**
```powershell
Get-TriliumAttachmentContent -AttachmentID "evnnmvHTCgIn"
```

---

### 🏷️ Get-TriliumAttribute

Retrieves the details of a specific Trilium attribute by its ID.

**Parameters:**
- `-AttributeID` (String, Required): The attribute ID to get details for.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the attribute details as a PowerShell object.

**Examples:**
```powershell
Get-TriliumAttribute -AttributeID "12345"
```

---

### 🌳 Get-TriliumBranch

Retrieves the details of a specific Trilium branch (tree structure) by its ID, including its children and metadata.

**Parameters:**
- `-BranchID` (String, Required): The branch ID to get details for.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the branch details as a PowerShell object, including child notes.

**Examples:**
```powershell
Get-TriliumBranch -BranchID "A2PGuqZgT03z_sxhoPPMkVIuO"
```
Retrieves details for the specified branch, including its children.

> [!NOTE]
> Use this to explore the tree structure of your notes for navigation or automation.

---

### 📅 Get-TriliumDayNote

Retrieves the daily note for a specific date from your Trilium instance. Useful for journaling or daily logs.

**Parameters:**
- `-Date` (String, Required): The date for the daily note (format: yyyy-MM-dd).
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the daily note object, including its content and metadata.

**Examples:**
```powershell
Get-TriliumDayNote -Date "2025-06-18"
```
Retrieves the daily note for June 18, 2025.

---

### 📥 Get-TriliumInbox

Retrieves the inbox note for your Trilium instance, which is often used as a default location for quick notes.

**Parameters:**
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the inbox note object.

**Examples:**
```powershell
Get-TriliumInbox
```
Retrieves the inbox note.

---

### 📅 Get-TriliumMonthNote

Retrieves the monthly note for a specific month from your Trilium instance. Useful for monthly planning or summaries.

**Parameters:**
- `-Month` (String, Required): The month for the note (format: yyyy-MM).
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the monthly note object.

**Examples:**
```powershell
Get-TriliumMonthNote -Month "2025-06"
```
Retrieves the monthly note for June 2025.

---

### 📎 Get-TriliumNoteAttachment

Retrieves all attachments for a specific Trilium note by note ID.

**Parameters:**
- `-NoteID` (String, Required): The note ID to retrieve attachments for.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns a list of attachment objects for the note.

**Examples:**
```powershell
Get-TriliumNoteAttachment -NoteID "<note-id>"
```
Retrieves all attachments for the specified note.

---

### 📝 Get-TriliumNoteContent

Retrieves the content of a specific Trilium note by note ID.

**Parameters:**
- `-NoteID` (String, Required): The note ID to retrieve content for.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the note content as a string.

**Examples:**
```powershell
Get-TriliumNoteContent -NoteID "<note-id>"
```
Retrieves the content of the specified note.

---

### 📅 Get-TriliumWeekNote

Retrieves the weekly note for a specific week from your Trilium instance. Useful for weekly planning or summaries.

**Parameters:**
- `-Week` (String, Required): The week for the note (format: yyyy-'W'ww, e.g., 2025-W25).
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the weekly note object.

**Examples:**
```powershell
Get-TriliumWeekNote -Week "2025-W25"
```
Retrieves the weekly note for week 25 of 2025.

---

### 📅 Get-TriliumYearNote

Retrieves the yearly note for a specific year from your Trilium instance. Useful for annual planning or summaries.

**Parameters:**
- `-Year` (String, Required): The year for the note (format: yyyy).
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the yearly note object.

**Examples:**
```powershell
Get-TriliumYearNote -Year "2025"
```
Retrieves the yearly note for 2025.

---

### 📦 Import-TriliumNoteZip

Imports a note from a Trilium zip export file into your Trilium instance.

**Parameters:**
- `-Path` (String, Required): The path to the Trilium zip file to import.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the imported note object.

**Examples:**
```powershell
Import-TriliumNoteZip -Path "C:\path\to\import.zip"
```
Imports a note from the specified zip file.

---

### 📎 New-TriliumAttachment

Adds a new attachment to a Trilium note.

**Parameters:**
- `-NoteID` (String, Required): The note ID to attach the file to.
- `-Path` (String, Required): The path to the file to attach.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the new attachment object.

**Examples:**
```powershell
New-TriliumAttachment -NoteID "<note-id>" -Path "C:\path\to\file"
```
Attaches the specified file to the note.

---

### 🏷️ New-TriliumAttribute

Adds a new attribute to a Trilium note.

**Parameters:**
- `-NoteID` (String, Required): The note ID to add the attribute to.
- `-Name` (String, Required): The name of the attribute.
- `-Value` (String, Required): The value of the attribute.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the new attribute object.

**Examples:**
```powershell
New-TriliumAttribute -NoteID "<note-id>" -Name "key" -Value "value"
```
Adds a new attribute to the note.

---

### 💾 New-TriliumBackup

Creates a backup of your Trilium instance and saves it as a zip file.

**Parameters:**
- `-Path` (String, Required): The path to save the backup zip file.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the path to the backup file.

**Examples:**
```powershell
New-TriliumBackup -Path "C:\backup\trilium.zip"
```
Creates a backup and saves it to the specified path.

---

### 📄 New-TriliumNoteFile

Creates a new note in Trilium from a file.

**Parameters:**
- `-Path` (String, Required): The path to the file to import as a note.
- `-ParentNoteId` (String, Optional): The parent note ID (default: root).
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the new note object.

**Examples:**
```powershell
New-TriliumNoteFile -Path "C:\path\to\file.md" -ParentNoteId "root"
```
Creates a new note from the specified file.

---

### 🕓 New-TriliumNoteRevision

Creates a new revision for a note, allowing you to track changes over time.

**Parameters:**
- `-NoteID` (String, Required): The note ID to add a revision to.
- `-Content` (String, Required): The new content for the revision.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the new revision object.

**Examples:**
```powershell
New-TriliumNoteRevision -NoteID "<note-id>" -Content "Updated content"
```
Adds a new revision to the note.

---

### 🗑️ Remove-TriliumAttachment

Deletes an attachment from a note by attachment ID.

**Parameters:**
- `-AttachmentID` (String, Required): The attachment ID to remove.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
None. The attachment is deleted from the note.

**Examples:**
```powershell
Remove-TriliumAttachment -AttachmentID "<attachment-id>"
```
Deletes the specified attachment.

---

### 🗑️ Remove-TriliumAttribute

Deletes an attribute from a note by attribute name.

**Parameters:**
- `-NoteID` (String, Required): The note ID to remove the attribute from.
- `-Name` (String, Required): The name of the attribute to remove.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
None. The attribute is deleted from the note.

**Examples:**
```powershell
Remove-TriliumAttribute -NoteID "<note-id>" -Name "key"
```
Deletes the specified attribute from the note.

---

### 🗑️ Remove-TriliumBranch

Deletes a branch (subtree) from your Trilium notes by branch ID.

**Parameters:**
- `-NoteID` (String, Required): The branch (note) ID to remove.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
None. The branch is deleted from your notes.

**Examples:**
```powershell
Remove-TriliumBranch -NoteID "<note-id>"
```
Deletes the specified branch.

---

### 🗑️ Remove-TriliumNote

Deletes a note from your Trilium instance by note ID.

**Parameters:**
- `-NoteID` (String, Required): The note ID to remove.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
None. The note is deleted from your Trilium instance.

**Examples:**
```powershell
Remove-TriliumNote -NoteID "<note-id>"
```
Deletes the specified note.

---

### 🛠️ Set-TriliumBranch

Updates properties of a branch in your Trilium notes, such as expansion state.

**Parameters:**
- `-NoteID` (String, Required): The branch (note) ID to update.
- `-IsExpanded` (Boolean, Optional): Whether the branch is expanded in the UI.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the updated branch object.

**Examples:**
```powershell
Set-TriliumBranch -NoteID "<note-id>" -IsExpanded $true
```
Expands the specified branch in the UI.

---

### 🛠️ Set-TriliumNoteContent

Updates the content of a Trilium note by note ID.

**Parameters:**
- `-NoteID` (String, Required): The note ID to update.
- `-Content` (String, Required): The new content for the note.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the updated note object.

**Examples:**
```powershell
Set-TriliumNoteContent -NoteID "<note-id>" -Content "Updated content"
```
Updates the content of the specified note.

---

### 🛠️ Set-TriliumNoteDetails

Updates the details (title, type, etc.) of a Trilium note by note ID.

**Parameters:**
- `-NoteID` (String, Required): The note ID to update.
- `-Title` (String, Optional): The new title for the note.
- `-NoteType` (String, Optional): The new type for the note.
- `-Mime` (String, Optional): The new MIME type for the note.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the updated note object.

**Examples:**
```powershell
Set-TriliumNoteDetails -NoteID "<note-id>" -Title "Updated Title"
```
Updates the title of the specified note.

---

### 🔄 Update-TriliumNoteOrder

Changes the order of notes under a parent note in your Trilium instance.

**Parameters:**
- `-ParentNoteId` (String, Required): The parent note ID whose children will be reordered.
- `-NoteIds` (Array, Required): An array of note IDs in the desired order.
- `-SkipCertCheck` (Switch, Optional): Ignore SSL certificate errors (useful for self-signed certs).

**Output:**  
Returns the updated order of notes.

**Examples:**
```powershell
Update-TriliumNoteOrder -ParentNoteId "<parent-note-id>" -NoteIds @("id1","id2")
```
Reorders the child notes under the specified parent.

---