-- Create `book` table and its trigger
DO $$
BEGIN
    -- Check the reference tables
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'app_id'
    ) THEN
        RAISE NOTICE 'Table: `app_id` does not exists, `book` table was not created';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'record_status'
    ) THEN
        RAISE NOTICE 'Table: `record_status` does not exists, `book` table was not created';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'author'
    ) THEN
        RAISE NOTICE 'Table: `author` does not exists, `book` table was not created';
        RETURN;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'publisher'
    ) THEN
        RAISE NOTICE 'Table: `publisher` does not exists, `book` table was not created';
        RETURN;
    END IF;

    -- Create the table
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'book'
    ) THEN
        
        CREATE TABLE public.book (
            book_app_id CHAR(25) PRIMARY KEY,
            book_status_id INTEGER NOT NULL,
            author_app_id CHAR(25) NOT NULL,
            publisher_app_id CHAR(25) NOT NULL,
            title VARCHAR(255) NOT NULL,
            publication_date DATE NOT NULL,
            page_count INT DEFAULT NULL,
            FOREIGN KEY (book_app_id) REFERENCES app_id(full_app_id),
            FOREIGN KEY (book_status_id) REFERENCES record_status(record_status_id),
            FOREIGN KEY (author_app_id) REFERENCES author(author_app_id),
            FOREIGN KEY (publisher_app_id) REFERENCES publisher(publisher_app_id)
        );
        RAISE NOTICE 'Table: `book` created';
    
    ELSE
        RAISE NOTICE 'Table: `book` already exists';
    END IF;
    
    -- Create the trigger function
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'before_insert_book'
    ) THEN
    
      CREATE FUNCTION before_insert_book()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      AS $func$
      BEGIN
          -- Generate the status
          INSERT INTO record_status(created_date)
          VALUES (CURRENT_TIMESTAMP)
          RETURNING record_status_id INTO NEW.book_status_id;
          
          -- Generate the app_id
          INSERT INTO app_id(prefix)
          VALUES ('PBLS')
          RETURNING full_app_id INTO NEW.book_app_id;
          
          RETURN NEW;
      END $func$;
      RAISE NOTICE 'Func: `before_insert_book()` created';
    
    ELSE 
      RAISE NOTICE 'Func: `before_insert_book()` already exists';
    END IF;
    
    -- Create the table trigger
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE t.tgname = 'trg_before_insert_book'
            AND c.relname = 'book'
            AND n.nspname = 'public'
    ) THEN
      CREATE TRIGGER trg_before_insert_book
      BEFORE INSERT ON public.book
      FOR EACH ROW
      EXECUTE FUNCTION before_insert_book();
      RAISE NOTICE 'Trigg: `trg_before_insert_book` created';
    
    ELSE 
      RAISE NOTICE 'Trigg: `trg_before_insert_book` already exists';
    END IF;
END$$;