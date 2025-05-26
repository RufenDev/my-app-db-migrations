-- Create `author` table and its trigger
DO $$
BEGIN
    -- Check the reference tables
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'app_id'
    ) THEN
        RAISE NOTICE 'Table: `app_id` does not exists, `author` table was not created';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'record_status'
    ) THEN
        RAISE NOTICE 'Table: `record_status` does not exists, `author` table was not created';
        RETURN;
    END IF;

    -- Create the table
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'author'
    ) THEN
        
        CREATE TABLE public.author (
            author_app_id CHAR(25) PRIMARY KEY,
            author_status_id INTEGER NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            middle_name VARCHAR(100) DEFAULT NULL,
            birthdate DATE DEFAULT NULL,
            nationality VARCHAR(255) DEFAULT NULL,
            FOREIGN KEY (author_app_id) REFERENCES app_id(full_app_id),
            FOREIGN KEY (author_status_id) REFERENCES record_status(record_status_id)
        );
        RAISE NOTICE 'Table: `author` created';
    
    ELSE
        RAISE NOTICE 'Table: `author` already exists';
    END IF;
    
    -- Create the trigger function
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'before_insert_author'
    ) THEN
    
      CREATE FUNCTION before_insert_author()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      AS $func$
      BEGIN
          -- Generate the status
          INSERT INTO record_status(created_date)
          VALUES (CURRENT_TIMESTAMP)
          RETURNING record_status_id INTO NEW.author_status_id;
          
          -- Generate the app_id
          INSERT INTO app_id(prefix)
          VALUES ('AUTH')
          RETURNING full_app_id INTO NEW.author_app_id;
          
          RETURN NEW;
      END $func$;
      RAISE NOTICE 'Func: `before_insert_author()` created';
    
    ELSE 
      RAISE NOTICE 'Func: `before_insert_author()` already exists';
    END IF;
    
    -- Create the table trigger
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE t.tgname = 'trg_before_insert_author'
            AND c.relname = 'author'
            AND n.nspname = 'public'
    ) THEN
      CREATE TRIGGER trg_before_insert_author
      BEFORE INSERT ON public.author
      FOR EACH ROW
      EXECUTE FUNCTION before_insert_author();
      RAISE NOTICE 'Trigg: `trg_before_insert_author` created';
    
    ELSE 
      RAISE NOTICE 'Trigg: `trg_before_insert_author` already exists';
    END IF;
END$$;