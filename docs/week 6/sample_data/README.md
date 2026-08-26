# Safe sample data for the Week 6 demonstration

`evercare_demo_dataset.json` contains deliberately fictional content for a disposable classroom account. It makes the app's lists, filters, history, update forms, and delete confirmations easy to demonstrate without exposing anyone's real care information.

## How to use it

1. Register or sign in with a disposable demo account.
2. Enter only the records prefixed **EverCare Demo** using the normal app forms. This demonstrates the same validation and authenticated CRUD path a real user would use.
3. Use the records to demonstrate create, read/search, update, and delete.
4. Delete every record whose title or name begins with **EverCare Demo** after the presentation.

## Do not use

- A real person's name, phone number, medication, appointment, journal, or blood-pressure reading.
- A real emergency contact number.
- The sample values to make a medical decision. The blood-pressure entries are interface fixtures only and are not clinical advice.

The app's normal owner-scoped Row Level Security and delete confirmations stay active while using this dataset.
