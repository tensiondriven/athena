const http = require('http');

const questions = [
  {
    question: 'Is the sky blue?',
    options: ['True', 'False']
  },
  {
    question: 'What is the capital of France?',
    options: ['Paris', 'London', 'Berlin', 'Madrid']
  },
  {
    question: 'Which planet is known as the Red Planet?',
    options: ['Earth', 'Mars', 'Jupiter', 'Saturn']
  }
];

function sendQuestion(question) {
  const data = JSON.stringify(question);

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/display-question',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  const req = http.request(options, (res) => {
    let responseBody = '';

    res.on('data', (chunk) => {
      responseBody += chunk.toString();
    });

    res.on('end', () => {
      console.log(`Response: ${responseBody}`);
    });
  });

  req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
  });

  req.write(data);
  req.end();
}

questions.forEach((question, index) => {
  setTimeout(() => {
    console.log(`Sending question ${index + 1}:`);
    sendQuestion(question);
  }, index * 5000); // Send each question 5 seconds apart
});