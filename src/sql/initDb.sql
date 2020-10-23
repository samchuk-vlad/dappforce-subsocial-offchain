-- Create custom types
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action') THEN
        CREATE TYPE df.action AS ENUM (
            'SpaceCreated',
            'SpaceUpdated',
            'SpaceFollowed',
            'SpaceUnfollowed',
            'AccountFollowed',
            'AccountUnfollowed',
            'PostCreated',
            'PostMoved',
            'PostUpdated',
            'PostShared',
            'CommentCreated',
            'CommentUpdated',
            'CommentShared',
            'CommentDeleted',
            'CommentReplyCreated',
            'PostReactionCreated',
            'PostReactionUpdated',
            'CommentReactionCreated',
            'CommentReactionUpdated'
        );
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account') THEN
        CREATE DOMAIN account as char(48);
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ipfs_cid') THEN
        CREATE DOMAIN ipfs_cid as varchar(59) CHECK (LENGTH(VALUE) >= 46);
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_type') THEN
        CREATE TYPE post_type as ENUM (
            'RegularPost',
            'SharedPost',
            'Comment'
        );
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS df.spaces
(
    id bigint NOT NULL primary key UNIQUE,
    created_by_account account NOT NULL,
    created_at_block bigint NOT NULL,
    created_at_time bigint NOT NULL,

    updated_by_account account NULL,
    updated_at_block bigint NULL,
    updated_at_time bigint NULL,

    owner account NOT NULL,

    parent_id bigint,
    handle varchar(48) NULL,
    content ipfs_cid NULL,
    hidden boolean NOT NULL DEFAULT false,

    posts_count integer NOT NULL DEFAULT 0,
    hidden_posts_count integer NOT NULL DEFAULT 0, 
    followers_count integer NOT NULL DEFAULT 0,
    
    score integer NOT NULL DEFAULT 0,
    FOREIGN KEY (parent_id) REFERENCES df.spaces(id)
    -- permissions df.permissions NULL
);

CREATE TABLE IF NOT EXISTS df.posts
(
    id bigint NOT NULL primary key UNIQUE,
    created_by_account account NOT NULL,
    created_at_block bigint NOT NULL,
    created_at_time bigint NOT NULL,

    updated_by_account account NULL,
    updated_at_block bigint NULL,
    updated_at_time bigint NULL,

    owner account NOT NULL,

    shared_post_id bigint,

    parent_id bigint,
    root_post_id bigint,

    space_id bigint,
    content ipfs_cid NULL,
    type post_type NOT NULL,
    hidden boolean NOT NULL DEFAULT false,

    replies_count integer NOT NULL DEFAULT 0,
    hidden_replies_count integer NOT NULL DEFAULT 0,
    shares_count integer NOT NULL DEFAULT 0,
    upvotes_count integer NOT NULL DEFAULT 0,
    downvotes_count integer NOT NULL DEFAULT 0,

    score integer NOT NULL DEFAULT 0,
    FOREIGN KEY (shared_post_id) REFERENCES df.posts(id),
    FOREIGN KEY (space_id) REFERENCES df.spaces(id),
    FOREIGN KEY (parent_id) REFERENCES df.posts(id),
    FOREIGN KEY (root_post_id) REFERENCES df.posts(id)
);

CREATE TABLE IF NOT EXISTS df.profile
(
    id bigserial NOT NULL UNIQUE,
    created_by_account account NOT NULL,
    created_at_block bigint NOT NULL,
    created_at_time bigint NOT NULL,

    updated_by_account account NULL,
    updated_at_block bigint NULL,
    updated_at_time bigint NULL,

    content ipfs_cid NULL    
);

CREATE TABLE IF NOT EXISTS df.activities
(
    id bigserial not null primary key UNIQUE,
    account varchar(48) NOT NULL,
    event df.action NOT NULL,
    following_id varchar(48) NULL,
    space_id varchar(16) NULL,
    post_id varchar(16) NULL,
    comment_id varchar(16) NULL,
    parent_comment_id varchar(16) NULL,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    block_number bigint NOT NULL,
    aggregated boolean NOT NULL DEFAULT true,
    agg_count bigint NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS df.news_feed
(
    account varchar(48) NOT NULL,
    activity_id bigint NOT NULL,
    FOREIGN KEY (activity_id) REFERENCES df.activities(id)
);

CREATE TABLE IF NOT EXISTS df.notifications
(
    account varchar(48) NOT NULL,
    activity_id bigint NOT NULL,
    FOREIGN KEY (activity_id) REFERENCES df.activities(id)
);

CREATE TABLE IF NOT EXISTS df.notifications_counter
(
    account varchar(48) NOT NULL UNIQUE,
    last_read_activity_id bigint DEFAULT NULL,
    unread_count bigint NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS df.account_followers
(
    follower_account varchar(48) NOT NULL,
    following_account varchar(48) NOT NULL
);

CREATE TABLE IF NOT EXISTS df.space_followers
(
    follower_account varchar(48) NOT NULL,
    following_space_id varchar(16) NOT NULL
);

CREATE TABLE IF NOT EXISTS df.post_followers
(
    follower_account varchar(48) NOT NULL,
    following_post_id varchar(16) NOT NULL
);

CREATE TABLE IF NOT EXISTS df.comment_followers
(
    follower_account varchar(48) NOT NULL,
    following_comment_id varchar(16) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_follower_account 
ON df.account_followers(follower_account);

CREATE INDEX IF NOT EXISTS idx_following_account 
ON df.account_followers(following_account);

CREATE INDEX IF NOT EXISTS idx_post_follower_account 
ON df.post_followers(follower_account);

CREATE INDEX IF NOT EXISTS idx_space_follower_account 
ON df.space_followers(follower_account);

CREATE INDEX IF NOT EXISTS idx_comment_follower_account 
ON df.comment_followers(follower_account);

CREATE INDEX IF NOT EXISTS idx_following_post_id 
ON df.post_followers(following_post_id);

CREATE INDEX IF NOT EXISTS idx_following_space_id 
ON df.space_followers(following_space_id);

CREATE INDEX IF NOT EXISTS idx_following_comment_id 
ON df.comment_followers(following_comment_id);

CREATE INDEX IF NOT EXISTS idx_id
ON df.activities(id);

CREATE INDEX IF NOT EXISTS idx_account
ON df.activities(account);

CREATE INDEX IF NOT EXISTS idx_event
ON df.activities(event);

CREATE INDEX IF NOT EXISTS idx_following_id
ON df.activities(following_id);

CREATE INDEX IF NOT EXISTS idx_post_id
ON df.activities(post_id);

CREATE INDEX IF NOT EXISTS idx_space_id
ON df.activities(space_id);

CREATE INDEX IF NOT EXISTS idx_comment_id
ON df.activities(comment_id);

CREATE INDEX IF NOT EXISTS idx_parent_comment_id
ON df.activities(parent_comment_id);

CREATE INDEX IF NOT EXISTS idx_aggregated
ON df.activities(aggregated);

-- CREATE TYPE IF NOT EXISTS df.permissions AS ENUM (
--     'ManageRoles',
--     'RepresentSpaceInternally',
--     'RepresentSpaceExternally',

--     'UpdateSpace',

--     'CreateSubspaces',
--     'UpdateOwnSubspaces',
--     'DeleteOwnSubspaces',
--     'HideOwnSubspaces',

--     'UpdateAnySubspace',
--     'DeleteAnySubspace',
--     'HideAnySubspace',

--     'CreatePosts',
--     'UpdateOwnPosts',
--     'DeleteOwnPosts',
--     'HideOwnPosts',

--     'UpdateAnyPost',
--     'DeleteAnyPost',
--     'HideAnyPost',

--     'CreateComments',
--     'UpdateOwnComments',
--     'DeleteOwnComments',
--     'HideOwnComments',

--     'HideAnyComment',

--     'Upvote',
--     'Downvote',
--     'Share',

--     'OverrideSubspacePermissions',
--     'OverridePostPermissions',

--     'SuggestEntityStatus',
--     'UpdateEntityStatus',

--     'UpdateSpaceSettings',
-- );

