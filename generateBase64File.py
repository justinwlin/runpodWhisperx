import base64

with open("example.mp3", "rb") as file:
    encoded_bytes = base64.b64encode(file.read())
    encoded_string = encoded_bytes.decode('utf-8')

# Write the encoded string to a file
with open("encoded.txt", "w") as file:
    file.write(encoded_string)