// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

document.addEventListener("DOMContentLoaded", function () {
  const voiceCaptureButton = document.getElementById("voice-capture-button");
  const chatInput = document.getElementById("chat-input");
  let recognizing = false;

  if (voiceCaptureButton) {
    const recognition = new (window.SpeechRecognition ||
      window.webkitSpeechRecognition)();
    recognition.lang = "en-US";
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;

    // Event listener for when recognition starts
    recognition.addEventListener("start", () => {
      recognizing = true;
      console.log("Speech recognition started.");
      voiceCaptureButton.innerHTML = "🛑"; // Change icon to stop
    });

    // Event listener for when recognition ends
    recognition.addEventListener("end", () => {
      recognizing = false;
      console.log("Speech recognition ended.");
      voiceCaptureButton.innerHTML = "🎤"; // Change icon back to microphone
    });

    // Voice capture button click event
    voiceCaptureButton.addEventListener("click", () => {
      if (!recognizing) {
        console.log("Voice capture button clicked, starting recognition.");
        recognition.start();
      } else {
        console.log("Stopping recognition.");
        recognition.stop(); // Stops the recognition
      }
    });

    // Event listener for capturing the speech recognition result
    recognition.addEventListener("result", (event) => {
      const speechResult = event.results[0][0].transcript;
      console.log("Speech recognized: ", speechResult);
      chatInput.value = speechResult; // Display the recognized speech in the input
    });

    // Error handling for speech recognition
    recognition.addEventListener("error", (event) => {
      console.error("Error occurred in speech recognition: ", event.error);
      if (event.error === "no-speech") {
        alert("No speech detected. Please try again.");
      }
      recognition.stop(); // Stop recognition on error
      voiceCaptureButton.innerHTML = "🎤"; // Reset the icon back to microphone
    });
  }
});
