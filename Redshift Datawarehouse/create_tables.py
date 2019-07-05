import configparser
import psycopg2
from sql_queries import create_table_queries, drop_table_queries


def drop_tables(cur, conn):
    """
    This query will be responsible for deleting pre-existing tables to ensure that our database does not throw any error
    if we try creating a table that already exists.
    """
    for query in drop_table_queries:
        cur.execute(query)
        conn.commit()


def create_tables(cur, conn):
    """
    This query will be responsible for creating the neccessary staging and analytics tables.
    """
    for query in create_table_queries:
        cur.execute(query)
        conn.commit()


def main():
    """
    This function connects to the redshift database and runs the drop_table and create_tables functions. 
    """
    config = configparser.ConfigParser()
    config.read('dwh.cfg')
    
    conn = psycopg2.connect("host={} dbname={} user={} password={} port={}".format(config.get('CLUSTER','HOST'),
                                                                                   config.get('DWH','DWH_DB'),
                                                                                   config.get('DWH','DWH_DB_USER'),
                                                                                   config.get('DWH','DWH_DB_PASSWORD'),
                                                                                   config.get('DWH','DWH_PORT')))
    cur = conn.cursor()

    drop_tables(cur, conn)
    create_tables(cur, conn)

    conn.close()


if __name__ == "__main__":
    main()