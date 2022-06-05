import random

from building_words import *

random.seed(42)

def random_title(words):
    return ' '.join(' '.join(map(str.capitalize, random.choice(bundle).split(' '))) for bundle in words)

def acronymize(title):
    return ''.join(word[0] for word in title.split(' '))

def random_date():
    year = random.randint(1940, 2021)
    month = random.randint(1, 12)
    day = random.randint(1, 28)
    return f'{year}-{month:0>2}-{day:0>2}'

def format_entry(entry):
    if entry is None:
        return 'NULL'
    if entry == ():
        return 'DEFAULT'
    if type(entry) == int:
        return str(entry)
    return f'\'{entry}\''

def random_journal():
    title = random_title(JOURNAL_WORDS)
    return ((), title, acronymize(title))

def random_person():
    first = random.choice(FIRST_NAMES)
    last = random.choice(LAST_NAMES)
    pseudonym = None
    if random.random() < 0.33:
        pseudonym = (first[0:random.randrange(0, len(first))] + last[0:random.randrange(0, len(last))]).capitalize()
    return ((), first, last, pseudonym)

def random_name():
    person = random_person()
    return f'{person[1]} {person[2]}'

def random_producer():
    return ((), random_title((MOVIE_ADJECTIVES, MOVIE_NOUNS)) + ' ' + random.choice(COMPANY_TYPES))

def random_movie():
    return ((), random_title(WORDS), str(random.randint(2, 180)) + ' minutes', random.randint(1, 19), random_date(), random.randint(1, len(LANGUAGES)))

def random_assoc(n, m):
    a = set()
    for i in range(1, n + 1):
        for _ in range(random.randint(1, 3)):
            a.add((i, random.randint(1, m)))
    return a

def insertion_command(table, rows):
    values = ',\n'.join('(' + ', '.join(map(format_entry, row)) + ')' for row in rows)
    return f'INSERT INTO {table}\nVALUES\n{values};\n'

def random_unique(generate, count):
    present = set()
    while len(present) < count:
        present.add(generate())
    return present

JOURNAL_COUNT = 20
PERSON_COUNT = 100
PRODUCER_COUNT = 20
MOVIE_COUNT = 100

LANGUAGES_INSERTION = insertion_command('languages', (((), lang) for lang in LANGUAGES))
JOURNALS_INSERTION = insertion_command('journals', random_unique(random_journal, JOURNAL_COUNT))
GENRES_INSERTION = insertion_command('genres', (((), *genre) for genre in GENRES))
PEOPLE_INSERTION = insertion_command('people', (random_person() for _ in range(PERSON_COUNT)))
PRODUCERS_INSERTION = insertion_command('producers', (random_producer() for _ in range(PRODUCER_COUNT)))
MOVIES_INSERTION = insertion_command('movies', (random_movie() for _ in range(MOVIE_COUNT)))
MOVIES_GENRES_INSERTION = insertion_command('movies_genres', random_assoc(MOVIE_COUNT, len(GENRES)))
MOVIES_PRODUCERS_INSERTION = insertion_command('movies_producers', random_assoc(MOVIE_COUNT, PRODUCER_COUNT))
MOVIES_DIRECTORS_INSERTION = insertion_command('movies_directors', random_assoc(MOVIE_COUNT, PERSON_COUNT))
MOVIES_COMPOSERS_INSERTION = insertion_command('movies_composers', random_assoc(MOVIE_COUNT, PERSON_COUNT))
MOVIES_SCREENWRITERS_INSERTION = insertion_command('movies_screenwriters', random_assoc(MOVIE_COUNT, PERSON_COUNT))
MOVIES_ACTORS_INSERTION = insertion_command('movies_actors', ((*a, random_name()) for a in random_assoc(MOVIE_COUNT, PERSON_COUNT)))

insertions = [
    LANGUAGES_INSERTION,
    JOURNALS_INSERTION,
    GENRES_INSERTION,
    PEOPLE_INSERTION,
    PRODUCERS_INSERTION,
    MOVIES_INSERTION,
    MOVIES_GENRES_INSERTION,
    MOVIES_PRODUCERS_INSERTION,
    MOVIES_DIRECTORS_INSERTION,
    MOVIES_COMPOSERS_INSERTION,
    MOVIES_SCREENWRITERS_INSERTION,
    MOVIES_ACTORS_INSERTION
]

sql = '\n'.join(insertions)

with open('cnema/db/fill.sql', 'w') as f:
    f.write(f'{sql}\n')
