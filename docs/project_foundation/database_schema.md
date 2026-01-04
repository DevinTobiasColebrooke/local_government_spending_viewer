# Database Schema Plan

## Entity Relationship Diagram (ERD)
<!-- TODO: Add Mermaid ER Diagram here -->

```mermaid
erDiagram
    USER ||--o{ POST : has
    USER {
        string email
        string password_digest
    }
    POST {
        string title
        text content
    }
```

## Table Definitions

### Users
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id     | uuid | PK          |             |
| email  | string| unique, index|             |

<!-- TODO: Add planned tables here before generating migrations -->
