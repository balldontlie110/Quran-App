
import json

# with open('english.txt', 'r') as file:
#     english = file.readlines()

# with open('arabic.txt', 'r') as file:
#     arabic = file.readlines()

# with open('transliteration.txt', 'r') as file:
#     transliteration = file.readlines()

# ziarat = {
#     "verses": []
# }

# verseIndex = 0
# gapIndex = 0

# for index in range(0, len(english)):
#     gap = False
#     if arabic[index].rstrip() == "":
#         gap = True
#         gapIndex -= 1
#     else:
#         verseIndex += 1

#     verse = {
#         "id": verseIndex if gap == False else gapIndex,
#         "text": arabic[index].rstrip(),
#         "translation": english[index].rstrip(),
#         "transliteration": transliteration[index].rstrip(),
#         "gap": gap
#     }

#     ziarat["verses"].append(verse)

# with open("ziarat.json", "w", encoding='utf-8') as file:
#     json.dump(ziarat, file, ensure_ascii=False, indent=4)

with open('ziarat.txt', 'r') as file:
    ziarat = file.readlines()

ziyarat = {
    "title": "Friday Ziyarat",
    "subtitle": "Imam Mahdi (as)",
    "verses": []
}

arabic = []
transliteration = []
english = []

for index, line in enumerate(ziarat):
    if (index + 1) % 4 == 0:
        english.append(line.rstrip())
    elif (index + 2) % 4 == 0:
        transliteration.append(line.rstrip())
    elif (index + 3) % 4 == 0:
        arabic.append(line.rstrip())

for index in range(0, len(arabic)):
    verse = {
        "id": index + 1,
        "text": arabic[index],
        "translation": english[index],
        "transliteration": transliteration[index],
        "gap": False
    }

    ziyarat["verses"].append(verse)

with open("ziarat.json", "w", encoding='utf-8') as file:
    json.dump(ziyarat, file, ensure_ascii=False, indent=4)
