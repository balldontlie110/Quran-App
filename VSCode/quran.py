
import json

with open('quran.json', 'r') as file:
    quran = json.load(file)

with open('arabicWBW.json', 'r') as file:
    arabicWBW = list(json.load(file).values())

with open('englishWBW.json', 'r') as file:
    englishWBW = list(json.load(file).values())

with open('words.json', 'r') as file:
    words = list(json.load(file).values())


for surahIndex, surah in enumerate(quran):
    for verseIndex, verse in enumerate(surah["verses"]):
        # quran[surahIndex]["verses"][verseIndex].pop("translations")

        quran[surahIndex]["verses"][verseIndex]["words"] = []

        for wordIndex, word in enumerate(words):
            surah = word["surah"]
            ayah = word["ayah"]
            position = word["position"]

            if surah == surahIndex + 1 and ayah == verseIndex + 1:
                newWord = {
                    "id": f"{ayah}-{position + 1}",
                    "text": arabicWBW[wordIndex],
                    "translation": englishWBW[wordIndex]
                }

                quran[surahIndex]["verses"][verseIndex]["words"].append(newWord)

with open("quran.json", "w", encoding='utf-8') as file:
    json.dump(quran, file, ensure_ascii=False, indent=4)
