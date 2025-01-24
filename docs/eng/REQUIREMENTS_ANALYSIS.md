**EN** | [PL](../pl/ANALIZA_WYMAGAN.md)

[Home](../../README.md) > Requirements Analysis

# Requirements Analysis

## Objective

The application aims to help users manage their household budget by recording income and expenses, analyzing financial flows, and generating summaries and reports.

## Scope

The database will support users, their wallets, groups, expense categories, and financial reports.

## Functional Requirements

The application's functionality has been divided into the following modules:

### Users

- User registration
- User login and active session management
- Storing user information, such as:
  - Email;
  - First and last name;
  - Unique nickname;
  - Encrypted password;
  - Citizenship;
- Support for multiple users with separation of their data

### Wallets

- Ability for users to create multiple wallets
- Wallets can be created in different currencies
- Users can deposit and withdraw money from wallets

### Groups

- A group can include multiple users
- Each group has:
  - A name;
  - A description (optional);
  - A picture (optional);
- Users can create and join groups
- Users within groups are assigned roles:
  - Administrator;
  - Guest;

### Transactions

- Recording income and expenses
- Associating transactions with users, groups, and wallets
- Categorizing transactions with categories and subcategories (optional)
- Transactions can only be performed if the wallet has sufficient funds

### Categories

- Creating custom categories and subcategories
- Generating summaries based on categories
- Using categories in transactions
- 
### Reports

- Generating financial reports:
  - Balance of income and expenses for a selected period;
  - Breakdown of expenses by category

## Non-Functional Requirements

### Security

- Storing salted passwords
- Restricted access to user data—each user can only view their own data
- Only administrators can add, modify permissions, and remove users from a group

## Compatibility

- Compatibility with the `PostgreSQL` system

## Performance

- Query response time should not exceed 1 second for typical operations