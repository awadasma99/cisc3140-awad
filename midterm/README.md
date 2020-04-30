## Midterm 2 - Part 2

I decided to implement my own input mask so as to get a better understanding of how event listeners work and how
HTML/CSS/Javascript work together to create a dynamic webpage. (First TODO) The input is retreived from the html file via
the class attribute using the setupInput function. I then attached two event listeners to the input, one to replace the
input with its formatted version (second TODO), and one to limit the displayed input to numeric values only. The input
is formatted using almost the same method as the method provided in the script.js file, but with the added line to 
handle the extra "-" (fourth TODO)and with a minor change to the condition so as to allow the "-" to appear 
immediately after the 3rd and 6th numbers are typed as opposed to only when the 4th and 7th numbers are typed. I utilized the
"maxlength" attribute in the html file so as to limit the formatted number to a length of 12, and the input to a length of 
10. Finally, (fifth TODO) in the CSS file, I used the border, border-bottom, and font-family properties to format the 
webpage as required. 
