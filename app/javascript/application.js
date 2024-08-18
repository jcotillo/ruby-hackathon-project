// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

document.addEventListener("DOMContentLoaded", function () {
  const voiceCaptureButton = document.getElementById("voice-capture-button");
  const attachmentButton = document.getElementById("attachment-button");
  const fileInput = document.getElementById("file-input");
  const chatInput = document.getElementById("chat-input");
  let recognizing = false;

  // Check if voiceCaptureButton exists before adding event listeners
  if (voiceCaptureButton) {
    const recognition = new (window.SpeechRecognition ||
      window.webkitSpeechRecognition)();
    recognition.lang = "en-US";
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;

    recognition.addEventListener("start", () => {
      recognizing = true;
      console.log("Speech recognition started.");
      voiceCaptureButton.innerHTML = "🛑"; // Change icon to stop
    });

    recognition.addEventListener("end", () => {
      recognizing = false;
      console.log("Speech recognition ended.");
      voiceCaptureButton.innerHTML = "🎤"; // Change icon back to microphone
    });

    voiceCaptureButton.addEventListener("click", () => {
      if (!recognizing) {
        console.log("Voice capture button clicked, starting recognition.");
        recognition.start();
      } else {
        console.log("Stopping recognition.");
        recognition.stop(); // Stops the recognition
      }
    });

    recognition.addEventListener("result", (event) => {
      const speechResult = event.results[0][0].transcript;
      console.log("Speech recognized: ", speechResult);
      chatInput.value = speechResult; // Display the recognized speech in the input
    });

    recognition.addEventListener("error", (event) => {
      console.error("Error occurred in speech recognition: ", event.error);
      if (event.error === "no-speech") {
        alert("No speech detected. Please try again.");
      }
      recognition.stop(); // Stop recognition on error
      voiceCaptureButton.innerHTML = "🎤"; // Reset the icon back to microphone
    });
  } else {
    console.warn("Voice capture button not found.");
  }

  // Check if attachmentButton exists before adding event listeners
  // if (attachmentButton) {
  //   attachmentButton.addEventListener("click", () => {
  //     if (fileInput) {
  //       fileInput.click(); // Trigger the file input dialog
  //     } else {
  //       console.warn("File input element not found.");
  //     }
  //   });

  // if (fileInput) {
  //   fileInput.addEventListener("change", (event) => {
  //     const file = event.target.files[0];
  //     if (file) {
  //       console.log("File selected:", file.name);
  //       chatInput.value = `Attachment: ${file.name}`; // Insert the filename into the chat input
  //     }
  //   });
  // }
  // } else {
  //   console.warn("Attachment button not found.");
  // }
});
