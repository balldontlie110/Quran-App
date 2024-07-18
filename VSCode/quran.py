
# - IMPORTS -

import json
import re
<<<<<<< HEAD
import requests


# - ONLY WANTED TRANSLATORS -

# with open('translators.json', 'r') as file:
#     translators = json.load(file)

# for index, translator in enumerate(translators["translations"]):
#     if translator["language_name"] != "french" and translator["language_name"] != "german" and translator["language_name"] != "urdu" and translator["language_name"] != "spanish" and translator["language_name"] != "korean" and translator["language_name"] != "turkish" and translator["language_name"] != "japanese" and translator["language_name"] != "chinese" and translator["language_name"] != "english":
#         translators["translations"].pop(index)

# with open("translators.json", "w", encoding='utf-8') as file:
#     json.dump(translators, file, ensure_ascii=False, indent=4)


# - CHANGE ARABIC TEXT -

# with open('arabic.json', 'r') as file:
#     arabic = json.load(file)

# with open('versesCount.txt', 'r') as file:
#     lines = file.readlines()
#     versesCount = [int(line.rstrip()) for line in lines]

# with open('quran-uthmani.txt', 'r') as file:
#     uthmani = file.readlines()

# surahNumber = 0
# verseNumber = 0
# for line in uthmani:
#     arabic[surahNumber]["verses"][verseNumber]["text"] = line.rstrip()
=======


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
>>>>>>> main

#     if verseNumber >= versesCount[surahNumber] - 1:
#         surahNumber += 1
#         verseNumber = 0
#     else:
#         verseNumber += 1

# with open("arabic.json", "w", encoding='utf-8') as file:
#     json.dump(arabic, file, ensure_ascii=False, indent=4)

<<<<<<< HEAD

# - REMOVE ALL TRANSLATIONS (THAT AREN'T OF SOME ID) -

with open("arabic.json", "r") as file:
    arabic = json.load(file)

for surahIndex, surah in enumerate(arabic):
    for verseIndex, verse in enumerate(surah["verses"]):
        for translationIndex, translation in enumerate(verse["translations"]):
            if translation["id"] != 131:
                arabic[surahIndex]["verses"][verseIndex]["translations"].pop(translationIndex)

with open("arabic.json", "w", encoding='utf-8') as file:
    json.dump(arabic, file, ensure_ascii=False, indent=4)

=======
# with open("arabic.json", "r") as file:
#     print(json.load(file)[0])


# - ADD AUDIO -

with open("audio.json", "r") as file:
    newArabic = json.load(file)["quran"]
>>>>>>> main

with open("arabic.json", "r") as file:
    arabic = json.load(file)

<<<<<<< HEAD

# - GET TRANSLATION -

# with open('arabic.json', 'r') as file:
#     arabic = json.load(file)

# with open("translators.json", "r") as file:
#     translators = json.load(file)

# translations = translators["translations"]

# for translation in translations:
#     if translation["language_name"] == "french" or translation["language_name"] == "german" or translation["language_name"] == "urdu" or translation["language_name"] == "spanish" or translation["language_name"] == "korean" or translation["language_name"] == "turkish" or translation["language_name"] == "japanese" or translation["language_name"] == "chinese" or translation["language_name"] == "english":
#         request = requests.get(f'https://api.quran.com/api/v4/quran/translations/{translation["id"]}')

#         with open("translation.json", "w", encoding='utf-8') as file:
#             json.dump(request.json(), file, ensure_ascii=False, indent=4)


# - CHANGE TRANSLATION -

#         with open("translation.json", "r") as file:
#             translation = json.load(file)

#         translations = translation["translations"]

#         with open("versesCount.txt", "r") as file:
#             lines = file.readlines()
#             versesCount = [int(line.rstrip()) for line in lines]

#         surahNumber = 0
#         verseNumber = 0
#         for verse in translations:
#             text = re.sub(r'<sup.*?</sup>', '', verse["text"])
#             text = re.sub(r'˹', '[', text)
#             text = re.sub(r'˺', ']', text)

#             # arabic[surahNumber]["verses"][verseNumber]["translations"] = []

#             # arabic[surahNumber]["verses"][verseNumber].pop("translation")

#             arabic[surahNumber]["verses"][verseNumber]["translations"].append({
#                 "id" : verse["resource_id"],
#                 "translation" : text
#             })

#             if verseNumber >= versesCount[surahNumber] - 1:
#                 surahNumber += 1
#                 verseNumber = 0
#             else:
#                 verseNumber += 1

# with open("arabic.json", "w", encoding='utf-8') as file:
#     json.dump(arabic, file, ensure_ascii=False, indent=4)

        # with open("arabic.json", "r") as file:
        #     print(json.load(file)[0])


# - ADD AUDIO -

# with open("audio.json", "r") as file:
#     newArabic = json.load(file)["quran"]

# with open("arabic.json", "r") as file:
#     arabic = json.load(file)

# quran = []

# for surah in arabic:
#     for ayat in surah["verses"]:
#         surah["verses"][ayat["id"] - 1]["text"] = [ re.sub("\u200f", "", new["text"]) for new in newArabic if new["chapter"] == surah["id"] and new["verse"] == ayat["id"] ][0]

#     quran.append(surah)

# with open("arabic.json", "w", encoding='utf-8') as file:
#     json.dump(quran, file, ensure_ascii=False, indent=4)
=======
quran = []

for surah in arabic:
    for ayat in surah["verses"]:
        surah["verses"][ayat["id"] - 1]["text"] = [ re.sub("\u200f", "", new["text"]) for new in newArabic if new["chapter"] == surah["id"] and new["verse"] == ayat["id"] ][0]

    quran.append(surah)

with open("arabic.json", "w", encoding='utf-8') as file:
    json.dump(quran, file, ensure_ascii=False, indent=4)
>>>>>>> main
