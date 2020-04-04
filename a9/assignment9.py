import json
import requests

url = "https://rawg-video-games-database.p.rapidapi.com/genres"

headers = {
    'x-rapidapi-host': "rawg-video-games-database.p.rapidapi.com",
    'x-rapidapi-key': # "your_API_key"
    }

response = requests.request("GET", url, headers=headers)

genre_list = json.loads(response.text)

print ("Available Genres:")

i = 0
for item in (genre_list["results"] ) :
    print ( "   " + str(i) + " " +   item['name'] )
    i = i + 1

input_genre = input("Please Choose a Genre # to See Associated RAWG Games: " )
chosen_genre = genre_list["results"][int(input_genre)]['name']

print("Genre chosen:" , chosen_genre)

url = "https://rawg-video-games-database.p.rapidapi.com/games"

headers = {
    'x-rapidapi-host': "rawg-video-games-database.p.rapidapi.com",
    'x-rapidapi-key': # "your_API_key"
    }

response = requests.request("GET", url, headers=headers)

games_list = json.loads(response.text)
games_in_genre = []

file = open("games.html", "w")
file.write("<html><head> <title> Categorized RAWG Games </title> </head>"
            + "<body bgcolor = D3D3D3> <h2> RAWG Games that Fall Under Genre: "
            + chosen_genre + " <h2><table> ")

count = 0

for game in (games_list["results"]) :
    for genre in (game["genres"]) :
        if (genre["name"] == chosen_genre) :
            file.write("<tr><td><img src='" + game['background_image'] +
            "' alt='" + game['name'] + "' height = '60' width = '60'></td><td><h3>" +
            game['name'] + "</h3></td></tr>")
            count = count + 1


file.write("</table></body></html>")
file.close()

if (count == 0) :
    print("Sorry, no RAWG games are currently registered in that category. Please try another.")
else :
    print("RAWG games in selected genre can be found in the file games.html!")
