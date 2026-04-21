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

  Serial.println("Client connected");

  // Wait for client data with timeout
  unsigned long timeout = millis() + 5000;
  String requestLine = "";
  
  while (client.connected() && millis() < timeout) {
    if (client.available()) {
      requestLine = client.readStringUntil('\r');
      break;
    }
    delay(1);
  }

  if (requestLine.length() == 0) {
    Serial.println("No request received, closing");
    client.stop();
    return;
  }

  Serial.println("Request: " + requestLine);

  // Read and discard headers
  while (client.available()) {
    String header = client.readStringUntil('\n');
    if (header == "\r" || header.length() <= 1) {
      break;
    }
  }

  // Handle CORS preflight
  if (requestLine.indexOf("OPTIONS") >= 0) {
    Serial.println("Handling OPTIONS request");
    client.print("HTTP/1.1 204 No Content\r\n");
    client.print("Access-Control-Allow-Origin: *\r\n");
    client.print("Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n");
    client.print("Access-Control-Allow-Headers: Content-Type\r\n");
    client.print("Access-Control-Max-Age: 86400\r\n");
    client.print("Connection: close\r\n");
    client.print("\r\n");
    client.flush();
    delay(100);
    client.stop();
    Serial.println("OPTIONS response sent");
    return;
  }

  // Read sensor data
  int sensorValue = analogRead(sensorPin);
  int rawHeartRateData = sensorValue;
  int realHeartRateData = map(sensorValue, 0, 1023, 60, 120);

  String responseBody = "Raw Heart Rate Data: " + String(rawHeartRateData) +
                        "\nReal Heart Rate Data: " + String(realHeartRateData);

  Serial.println("Response body: " + responseBody);

  // Send HTTP response with CORS headers
  client.print("HTTP/1.1 200 OK\r\n");
  client.print("Content-Type: text/plain\r\n");
  client.print("Content-Length: " + String(responseBody.length()) + "\r\n");
  client.print("Access-Control-Allow-Origin: *\r\n");
  client.print("Access-Control-Allow-Methods: GET, OPTIONS\r\n");
  client.print("Connection: close\r\n");
  client.print("\r\n");
  client.print(responseBody);

  // Wait for data to be sent before closing
  client.flush();
  delay(100);
  client.stop();
  Serial.println("Response sent and connection closed");
}
