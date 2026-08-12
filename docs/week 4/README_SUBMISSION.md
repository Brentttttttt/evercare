# EverCare Week 4 — CRUD Implementation

**Student:** Brent Lawrence C. Bernardo  
**Section:** ITE231  
**Professor:** Paul John Cabance  
**Prepared:** August 12, 2026  
**Due:** August 17, 2026 at 7:00 PM

## Submission files

- `EverCare_Week4_CRUD_Documentation.pdf` — primary submission document.
- `EverCare_Week4_CRUD_Documentation.docx` — editable copy of the documentation.
- `EverCare_Week4_Source_Code.zip` — runnable Flutter/Supabase source snapshot.
- `screenshots/` — screenshots showing validation and the Create, Read, Update, and Delete workflow.
- `VERIFICATION_RESULTS.txt` — build, analysis, test, archive, and live CRUD verification summary.

## CRUD entity

The Week 4 entity is **Journal Entries**. The production EverCare application already implements all four required operations through `JournalRepository` and Supabase:

- **Create:** Add Journal Entry form → `createEntry()` → database insert.
- **Read:** Journal list and diary reader → `fetchEntries()` → owner-scoped database select.
- **Update:** Prefilled Edit Journal Entry form → `updateEntry()` → owner-scoped database update.
- **Delete:** Permanent-delete confirmation → `deleteEntry()` → Storage cleanup and database delete.

The form validates required title and body fields, trims input, prevents double submission, protects unsaved changes, and confirms destructive deletion. Supabase Row Level Security limits journal records and private photo attachments to the authenticated owner.

## Screenshot index

1. `01_data_validation.png` — required-field validation.
2. `02_create_entry_form.png` — Create form with a title.
3. `03_create_entry_content.png` — Create form with journal body content.
4. `04_create_and_read_list.png` — newly stored record displayed in the journal list.
5. `05_read_entry.png` — full read-only diary view.
6. `06_update_entry_form.png` — prefilled Update form.
7. `07_update_entry_content.png` — updated journal body.
8. `08_update_result.png` — persisted updated record displayed in the list.
9. `09_delete_confirmation.png` — safe Delete confirmation.
10. `10_delete_result.png` — refreshed list after deletion.

The temporary classroom entry was deleted after the screenshots were captured. No patient health information was used.

## Repository

https://github.com/Brentttttttt/evercare

## Running the source

1. Extract `EverCare_Week4_Source_Code.zip`.
2. Run `flutter pub get`.
3. Use the project's configured Supabase environment.
4. Run `flutter run` and sign in.
5. Open **Journals** to reproduce the CRUD workflow.

