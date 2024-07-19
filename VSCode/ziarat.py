
import json

with open('english.txt', 'r') as file:
    english = file.readlines()

with open('arabic.txt', 'r') as file:
    arabic = file.readlines()

with open('transliteration.txt', 'r') as file:
    transliteration = file.readlines()

ziarat = {
    "verses": []
}

verseIndex = 0
gapIndex = 0

for index in range(0, len(english)):
    gap = False
    if arabic[index].rstrip() == "":
        gap = True
        gapIndex -= 1
    else:
        verseIndex += 1

    verse = {
        "id": verseIndex if gap == False else gapIndex,
        "text": arabic[index].rstrip(),
        "translation": english[index].rstrip(),
        "transliteration": transliteration[index].rstrip(),
        "gap": gap
    }

    ziarat["verses"].append(verse)

with open("ziarat.json", "w", encoding='utf-8') as file:
    json.dump(ziarat, file, ensure_ascii=False, indent=4)
