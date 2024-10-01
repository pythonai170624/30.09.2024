
import psycopg2
import psycopg2.extras

connection = psycopg2.connect(
    host="localhost",
    database="postgres",
    user="admin",  # postgres
    password="admin",
    port="5556"
)

cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
#
# select_query = "SELECT * FROM sp_get_movies_mid();"
# cursor.execute(select_query)
#
# [{'id': 2, 'title': 'wonder woman', 'release_date': datetime.datetime(2018, 7, 11, 8, 12, 11), 'price': 125.5, 'country_id': 3, 'country_name': 'JAPAN'},
#  {'id': 2, 'title': 'wonder woman', 'release_date': datetime.datetime(2018, 7, 11, 8, 12, 11), 'price': 125.5, 'country_id': 3, 'country_name': 'JAPAN'},
#  {'id': 2, 'title': 'wonder woman', 'release_date': datetime.datetime(2018, 7, 11, 8, 12, 11), 'price': 125.5, 'country_id': 3, 'country_name': 'JAPAN'},]
# rows = cursor.fetchall()
# for row in rows:
#     rows_dict = dict(row)
#     print(rows_dict)
#     print(f"ID: {row['id']} TITLE: {row['title']:^20}, R.D.: {row['release_date']}, " +\
#           f"PRICE: {row['price']} COUNTRY: {row['country_name']:^8} ")
#

insert_query = """insert into movies (title, release_date, price, country_id)
values (%s, %s, %s, %s) returning id;
"""
insert_values = ('Joker 2', '2024-09-30 20:21:00', 59, 3)
# print("%s %d".format('hi', 1))
cursor.execute(insert_query, insert_values)
new_id = cursor.fetchone()[0]
print('new_id', new_id)

connection.commit()

cursor.close()
connection.close()