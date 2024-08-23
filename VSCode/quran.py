
import json


with open('quran.json', 'r') as file:
    quran = json.load(file)


with open('arabicWBW.json', 'r') as file:
    arabicWBW = list(json.load(file).values())

with open('bengaliWBW.json', 'r') as file:
    bengaliWBW = list(json.load(file).values())

with open('germanWBW.json', 'r') as file:
    germanWBW = list(json.load(file).values())

with open('englishWBW.json', 'r') as file:
    englishWBW = list(json.load(file).values())

with open('persianWBW.json', 'r') as file:
    persianWBW = list(json.load(file).values())

with open('hindiWBW.json', 'r') as file:
    hindiWBW = list(json.load(file).values())

with open('indonesianWBW.json', 'r') as file:
    indonesianWBW = list(json.load(file).values())

with open('russianWBW.json', 'r') as file:
    russianWBW = list(json.load(file).values())

with open('tamilWBW.json', 'r') as file:
    tamilWBW = list(json.load(file).values())

with open('turkishWBW.json', 'r') as file:
    turkishWBW = list(json.load(file).values())

with open('urduWBW.json', 'r') as file:
    urduWBW = list(json.load(file).values())


wbws = {
    # "Bengali - bn": bengaliWBW,
    # "German - de": germanWBW,
    "English - en": englishWBW
    # "Persian - fa": persianWBW,
    # "Hindi - hi": hindiWBW,
    # "Indonesian - id": indonesianWBW,
    # "Russian - ru": russianWBW,
    # "Tamil - ta": tamilWBW,
    # "Turkish - tr": turkishWBW,
    # "Urdu - ur": urduWBW
}


with open('words.json', 'r') as file:
    words = list(json.load(file).values())


for surahIndex, surah in enumerate(quran):
    for verseIndex, verse in enumerate(surah["verses"]):
        # quran[surahIndex]["verses"][verseIndex].pop("words")

        quran[surahIndex]["verses"][verseIndex]["words"] = []

        for wordIndex, word in enumerate(words):
            surah = word["surah"]
            ayah = word["ayah"]
            position = word["position"]

            if surah == surahIndex + 1 and ayah == verseIndex + 1:
                translations = []

                for wbwLanguage, wbw in wbws.items():
                    code = wbwLanguage.split(" - ")[1]
                    language = wbwLanguage.split(" - ")[0]

                    translation = {
                        "id": code,
                        "language": language,
                        "translation": wbw[wordIndex]
                    }

                    translations.append(translation)

                newWord = {
                    "id": f"{ayah}-{position + 1}",
                    "text": arabicWBW[wordIndex],
                    "translations": translations
                }

                quran[surahIndex]["verses"][verseIndex]["words"].append(newWord)

with open("quran.json", "w", encoding='utf-8') as file:
    json.dump(quran, file, ensure_ascii=False, indent=4)

# https://github.com/hablullah/data-quran/raw/master/word-translation/{language_code}-qurancom.json
