-- Create `publisher` table and its trigger
DO $$
BEGIN
    -- Check the reference tables
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'app_id'
    ) THEN
        RAISE NOTICE 'Table: `app_id` does not exists, `publisher` table was not created';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'record_status'
    ) THEN
        RAISE NOTICE 'Table: `record_status` does not exists, `publisher` table was not created';
        RETURN;
    END IF;

    -- Create the table
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'publisher'
    ) THEN
        
        CREATE TABLE public.publisher (
            publisher_app_id CHAR(25) PRIMARY KEY,
            publisher_status_id INTEGER NOT NULL,
            name VARCHAR(255) NOT NULL,
            address VARCHAR(255),
            phone VARCHAR(50),
            email VARCHAR(255),
            FOREIGN KEY (publisher_app_id) REFERENCES app_id(full_app_id),
            FOREIGN KEY (publisher_status_id) REFERENCES record_status(record_status_id)
        );
        RAISE NOTICE 'Table: `publisher` created';
    
    ELSE
        RAISE NOTICE 'Table: `publisher` already exists';
    END IF;
    
    -- Create the trigger function
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'before_insert_publisher'
    ) THEN
    
      CREATE FUNCTION before_insert_publisher()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      AS $func$
      BEGIN
          -- Generate the status
          INSERT INTO record_status(created_date)
          VALUES (CURRENT_TIMESTAMP)
          RETURNING record_status_id INTO NEW.publisher_status_id;
          
          -- Generate the app_id
          INSERT INTO app_id(prefix)
          VALUES ('PBLS')
          RETURNING full_app_id INTO NEW.publisher_app_id;
          
          RETURN NEW;
      END $func$;
      RAISE NOTICE 'Func: `before_insert_publisher()` created';
    
    ELSE 
      RAISE NOTICE 'Func: `before_insert_publisher()` already exists';
    END IF;
    
    -- Create the table trigger
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE t.tgname = 'trg_before_insert_publisher'
            AND c.relname = 'publisher'
            AND n.nspname = 'public'
    ) THEN
      CREATE TRIGGER trg_before_insert_publisher
      BEFORE INSERT ON public.publisher
      FOR EACH ROW
      EXECUTE FUNCTION before_insert_publisher();
      RAISE NOTICE 'Trigg: `trg_before_insert_publisher` created';
    
    ELSE 
      RAISE NOTICE 'Trigg: `trg_before_insert_publisher` already exists';
    END IF;
END$$;