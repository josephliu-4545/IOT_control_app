#include <ESP8266WiFi.h>

const char* ssid = "jl";
const char* password = "jljljljl";

WiFiServer server(80);

const int sensorPin = A0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("Connecting to WiFi...");

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected");
  Serial.print("ESP IP Address: ");
  Serial.println(WiFi.localIP());

  server.begin();
  Serial.println("Server started");
}

void loop() {
  WiFiClient client = server.available();
  if (!client) {
    return;
  }

  // Wait for client to send data
  unsigned long timeout = millis() + 3000;
  while (!client.available() && millis() < timeout) {
    delay(1);
  }

  if (!client.available()) {
    client.stop();
    return;
  }

  // Read first line (request line)
  String requestLine = client.readStringUntil('\r');
  Serial.println(requestLine);

  // Read and discard remaining headers
  while (client.available()) {
    String header = client.readStringUntil('\n');
    if (header == "\r" || header.length() <= 1) {
      break;
    }
  }

  // Handle CORS preflight OPTIONS request
  if (requestLine.indexOf("OPTIONS") >= 0) {
    client.println("HTTP/1.1 204 No Content");
    client.println("Access-Control-Allow-Origin: *");
    client.println("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    client.println("Access-Control-Allow-Headers: Content-Type");
    client.println("Access-Control-Max-Age: 86400");
    client.println("Connection: close");
    client.println();
    client.stop();
    Serial.println("Sent OPTIONS response");
    return;
  }

  // Read sensor data
  int sensorValue = analogRead(sensorPin);
  int rawHeartRateData = sensorValue;
  int realHeartRateData = map(sensorValue, 0, 1023, 60, 120);

  String responseBody = "Raw Heart Rate Data: " + String(rawHeartRateData) +
                        "\nReal Heart Rate Data: " + String(realHeartRateData);

  // Send HTTP response with CORS headers - FIXED: proper CRLF line endings
  client.print("HTTP/1.1 200 OK\r\n");
  client.print("Content-Type: text/plain\r\n");
  client.print("Access-Control-Allow-Origin: *\r\n");
  client.print("Access-Control-Allow-Methods: GET, OPTIONS\r\n");
  client.print("Access-Control-Allow-Headers: Content-Type\r\n");
  client.print("Connection: close\r\n");
  client.print("\r\n");  // Empty line to separate headers from body
  client.print(responseBody);

  Serial.println("Sent response: " + responseBody);
  
  delay(10);
  client.stop();
}
