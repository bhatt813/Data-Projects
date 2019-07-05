import configparser
import psycopg2
from sql_queries import copy_table_queries, insert_table_queries


def load_staging_tables(cur, conn):
    """
    This function copys the data from s3 to the staging tables based on the statements in sql_queries.py
    """
    for query in copy_table_queries:
        cur.execute(query)
        conn.commit()


def insert_tables(cur, conn):
    """
    This function uses the insert statements in sql_queries.py to populate the analytics tables. 
    """
    for query in insert_table_queries:
        cur.execute(query)
        conn.commit()


def main():
    """
    This function connects to the redshift database and run the load_staging_tables and insert_tables functions.
    """
    config = configparser.ConfigParser()
    config.read('dwh.cfg')

    conn = psycopg2.connect("host={} dbname={} user={} password={} port={}".format(config.get('CLUSTER','HOST'),
                                                                                  config.get('DWH','DWH_DB'),
                                                                                  config.get('DWH','DWH_DB_USER'),
                                                                                  config.get('DWH','DWH_DB_PASSWORD'),
                                                                                  config.get('DWH','DWH_PORT')))
    cur = conn.cursor()
    
    load_staging_tables(cur, conn)
    insert_tables(cur, conn)

    conn.close()


if __name__ == "__main__":
    main()