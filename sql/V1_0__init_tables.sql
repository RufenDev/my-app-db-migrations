-- Create `record_status` table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'record_status'
    ) THEN
        RAISE NOTICE 'Table: `record_status` already exists';
        RETURN;
    END IF;

    CREATE TABLE public.record_status (
        record_status_id SERIAL PRIMARY KEY,
        created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(100) DEFAULT 'app',
        updated_date TIMESTAMP DEFAULT NULL,
        updated_by VARCHAR(100) DEFAULT NULL,
        is_deleted BOOLEAN DEFAULT FALSE
    );

    RAISE NOTICE 'Table: `record_status` created';
END$$;

-- Create `app_id` table and its trigger
DO $$
BEGIN
    -- Create the table
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public' AND tablename = 'app_id'
    ) THEN
    
        CREATE TABLE public.app_id (
            full_app_id CHAR(25) PRIMARY KEY,
            prefix CHAR(4) NOT NULL,
            value CHAR(16) UNIQUE NOT NULL,
            created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by VARCHAR(100) DEFAULT 'app'
        );
        RAISE NOTICE 'Table: `app_id` created';
        
    ELSE
        RAISE NOTICE 'Table: `app_id` already exists';
    END IF;

    -- Create the trigger function
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'generate_app_id'
    ) THEN
    
        CREATE FUNCTION generate_app_id()
            RETURNS TRIGGER
            LANGUAGE plpgsql
        AS $func$
        BEGIN
            -- Upper prefix
            NEW.prefix := UPPER(NEW.prefix);
            -- random hex value
            NEW.value := LEFT(UPPER(MD5(RANDOM()::TEXT)), 16);
            -- new app_id
            NEW.full_app_id := 'APP-' || NEW.prefix || '-' || NEW.value;
            RETURN NEW;
        END $func$;
        RAISE NOTICE 'Func: `generate_app_id()` created';
        
    ELSE
        RAISE NOTICE 'Func: `generate_app_id()` already exists';
    END IF;

    -- Create the table trigger
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE t.tgname = 'trg_generate_app_id'
            AND c.relname = 'app_id'
            AND n.nspname = 'public'
    ) THEN

        CREATE TRIGGER trg_generate_app_id
        BEFORE INSERT ON public.app_id
        FOR EACH ROW
        EXECUTE FUNCTION generate_app_id();
        RAISE NOTICE 'Trigg: `trg_generate_app_id` created';

    ELSE
        RAISE NOTICE 'Trigg: `trg_generate_app_id` trigger: already exists';
    END IF;

END $$;
