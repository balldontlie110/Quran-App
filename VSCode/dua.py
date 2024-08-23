
import json

with open('dua.txt', 'r') as file:
    lines = file.readlines()

dua = {
    "id": 8,
    "title": "Dua before exams",
    "subtitle": None,
    "audio": None
}

arabic = []
transliterations = []
english = []

for index, line in enumerate(lines):
    if (index + 1) % 4 == 0:
        english.append(line.rstrip())
    elif (index + 2) % 4 == 0:
        transliterations.append(line.rstrip())
    elif (index + 3) % 4 == 0:
        arabic.append(line.rstrip())

verses = []

for index, arabic in enumerate(arabic):
    verse = {
        "id": index + 1,
        "text": arabic,
        "translation": english[index],
        "transliteration": transliterations[index],
        "audio": None
    }

    verses.append(verse)

dua["verses"] = verses

with open("dua.json", "w", encoding='utf-8') as file:
    json.dump(dua, file, ensure_ascii=False, indent=4)
