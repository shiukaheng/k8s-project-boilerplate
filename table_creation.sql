create table users (
    id bigserial primary key,
    email text not null unique,
    name text not null
);

create table nodes (
    id bigserial primary key,
    user_id bigint not null references users(id) on delete cascade,

    slug text not null,
    kind text not null check (kind in ('task', 'logic')),

    description text,
    due timestamptz,

    value boolean,
    value_last_changed timestamptz,

    logic_type text check (logic_type in ('AND', 'OR', 'NOT', 'XOR')),

    unique (user_id, slug),
    unique (user_id, id),

    check (
        (kind = 'task'
         and value is not null
         and value_last_changed is not null
         and logic_type is null)
        or
        (kind = 'logic'
         and logic_type is not null
         and value is null
         and value_last_changed is null)
    )
);

create table edges (
    id bigserial primary key,

    user_id bigint not null references users(id) on delete cascade,

    parent bigint not null,
    child bigint not null,

    unique (user_id, parent, child),
    check (parent <> child),

    foreign key (user_id, parent)
        references nodes(user_id, id)
        on delete cascade,

    foreign key (user_id, child)
        references nodes(user_id, id)
        on delete cascade
);