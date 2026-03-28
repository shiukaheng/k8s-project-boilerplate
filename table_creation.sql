create table users (
    id bigserial primary key,
    email text not null unique,
    name text not null
);

create table nodes (                    -- create a new table called "nodes"

    id bigserial primary key,           -- "id" column
                                         -- type: bigserial
                                         --   - a large integer
                                         --   - auto-generated / auto-incrementing
                                         -- primary key:
                                         --   - uniquely identifies each row
                                         --   - cannot be null
                                         --   - there is only one primary key for the table

    user_id bigint not null references users(id) on delete cascade,
                                         -- "user_id" column
                                         -- type: bigint
                                         --   - a large integer
                                         -- not null:
                                         --   - every node must have a user_id
                                         -- references users(id):
                                         --   - this is a foreign key
                                         --   - user_id must match some existing users.id
                                         --   - so each node belongs to a valid user
                                         -- on delete cascade:
                                         --   - if that user row is deleted,
                                         --     all their nodes are automatically deleted too

    slug text not null,                 -- "slug" column
                                         -- type: text
                                         -- not null:
                                         --   - every node must have a slug
                                         -- slug is your human-readable identifier,
                                         -- like "buy-milk" or "morning-routine"

    kind text not null check (kind in ('task', 'logic')),
                                         -- "kind" column
                                         -- type: text
                                         -- not null:
                                         --   - every node must say what kind it is
                                         -- check (...):
                                         --   - extra rule enforced by the database
                                         -- kind must be one of:
                                         --   - 'task'
                                         --   - 'logic'

    description text,                   -- optional text description
                                         -- nullable because there is no "not null"

    due timestamptz,                    -- optional due time
                                         -- type: timestamptz = timestamp with time zone
                                         -- stores a date/time

    value boolean,                      -- optional boolean field
                                         -- used for task nodes
                                         -- for example:
                                         --   false = incomplete
                                         --   true  = complete

    value_last_changed timestamptz,     -- optional timestamp
                                         -- used for task nodes
                                         -- records when "value" last changed

    logic_type text check (logic_type in ('AND', 'OR', 'NOT', 'XOR')),
                                         -- optional text field
                                         -- used for logic nodes
                                         -- if present, must be one of:
                                         --   AND, OR, NOT, XOR

    unique (user_id, slug),             -- table-level constraint
                                         -- the pair (user_id, slug) must be unique
                                         -- meaning:
                                         --   one user cannot have two nodes with the same slug
                                         -- but different users can reuse the same slug

    check (                             -- table-level check constraint
                                         -- this enforces consistency between columns
                                         -- each row must satisfy ONE of the two cases below

        (kind = 'task'                  -- case 1: this row is a task node
         and value is not null          -- then task field "value" must exist
         and value_last_changed is not null
                                         -- and "value_last_changed" must exist
         and logic_type is null)        -- and logic_type must NOT exist

        or                              -- OR

        (kind = 'logic'                 -- case 2: this row is a logic node
         and logic_type is not null     -- then logic_type must exist
         and value is null              -- and task field "value" must NOT exist
         and value_last_changed is null)
                                         -- and "value_last_changed" must NOT exist
    )
);

create table edges (
    id bigserial primary key,
    user_id bigint not null references users(id) on delete cascade,
    parent bigint not null references nodes(id) on delete cascade,
    child bigint not null references nodes(id) on delete cascade,
    unique (user_id, parent, child)
    check (parent <> child)
);