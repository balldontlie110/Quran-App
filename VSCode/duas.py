
<<<<<<< HEAD
import json

# with open('duas.txt', 'r') as file:
#     lines = file.readlines()

# with open('duas.txt', 'w') as file:
#     cleanedLines = [line for line in lines if line != "\n"]
#     for line in cleanedLines:
#         file.write(line)


# with open('duas.txt', 'r') as file:
#     lines = file.readlines()

# with open('duas.txt', 'w') as file:
#     for index, line in enumerate(lines):
#         if (index + 2) % 3 != 0:
#             file.write(line)


# with open('duas.txt', 'r') as file:
#     lines = file.readlines()

# with open('duas.txt', 'w') as file:
#     for line in lines:
#         line = line.replace('“', "\"")
#         file.write(line)


# with open('duas.txt', 'r') as file:
#     lines = file.readlines()

# with open('duas.json', 'w', encoding='utf-8') as file:
#     arabic = [line.rstrip() for index, line in enumerate(lines) if index % 2 == 0]
#     english = [line.rstrip() for index, line in enumerate(lines) if index % 2 != 0]

#     lines = []

#     for index in range(0, len(arabic)):
#         line = {
#             "id" : index + 1,
#             "arabic" : arabic[index],
#             "translation" : english[index]
#         }

#         lines.append(line)

#     json.dump(lines, file, ensure_ascii=False, indent=4)

with open('duas.json', 'r') as file:
    duas = json.load(file)

for duaIndex, dua in enumerate(duas):
    for verseIndex, verse in enumerate(dua["verses"]):
        duas[duaIndex]["verses"][verseIndex]["audio"] = 0

with open('duas.json', 'w', encoding='utf-8') as file:
    json.dump(duas, file, ensure_ascii=False, indent=4)
=======
with open('duas.txt', 'r') as file:
    lines = file.readlines()

with open('duas.txt', 'w') as file:
    cleanedLines = [line for line in lines if line != "\n"]
    for line in cleanedLines:
        file.write(line)


with open('duas.txt', 'r') as file:
    lines = file.readlines()

with open('duas.txt', 'w') as file:
    for index, line in enumerate(lines):
        if (index + 2) % 3 != 0:
            file.write(line)


with open('duas.txt', 'r') as file:
    lines = file.readlines()

with open('duas.txt', 'w') as file:
    for line in lines:
        line = line.replace('“', "\"")
        file.write(line)


import json

with open('duas.txt', 'r') as file:
    lines = file.readlines()

with open('duas.json', 'w', encoding='utf-8') as file:
    arabic = [line.rstrip() for index, line in enumerate(lines) if index % 2 == 0]
    english = [line.rstrip() for index, line in enumerate(lines) if index % 2 != 0]

    lines = []

    for index in range(0, len(arabic)):
        line = {
            "id" : index + 1,
            "arabic" : arabic[index],
            "translation" : english[index]
        }

        lines.append(line)

    json.dump(lines, file, ensure_ascii=False, indent=4)
>>>>>>> main
