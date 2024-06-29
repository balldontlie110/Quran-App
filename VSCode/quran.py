
# - IMPORTS -

import json
import re


# - CHANGE TRANSLATION -

# with open("translation.json", "r") as file:
#     translation = json.load(file)

# translations = translation["translations"]

# with open("versesCount.txt", "r") as file:
#     lines = file.readlines()
#     versesCount = [int(line.rstrip()) for line in lines]

# with open("arabic.json", "r") as file:
#     arabic = json.load(file)

# surahNumber = 0
# verseNumber = 0
# for verse in translations:
#     text = re.sub(r'<sup.*?</sup>', '', verse["text"])
#     text = re.sub(r'˹', '[', text)
#     text = re.sub(r'˺', ']', text)

#     arabic[surahNumber]["verses"][verseNumber]["translation"] = text

#     if verseNumber >= versesCount[surahNumber] - 1:
#         surahNumber += 1
#         verseNumber = 0
#     else:
#         verseNumber += 1

# with open("arabic.json", "w", encoding='utf-8') as file:
#     json.dump(arabic, file, ensure_ascii=False, indent=4)

# with open("arabic.json", "r") as file:
#     print(json.load(file)[0])


# - ADD AUDIO -

with open("audio.json", "r") as file:
    newArabic = json.load(file)["quran"]

with open("arabic.json", "r") as file:
    arabic = json.load(file)

quran = []

for surah in arabic:
    for ayat in surah["verses"]:
        surah["verses"][ayat["id"] - 1]["text"] = [ re.sub("\u200f", "", new["text"]) for new in newArabic if new["chapter"] == surah["id"] and new["verse"] == ayat["id"] ][0]

    quran.append(surah)

with open("arabic.json", "w", encoding='utf-8') as file:
    json.dump(quran, file, ensure_ascii=False, indent=4)
