const { createServer } = require('http');
const { exec } = require('child_process');

const server = createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/display-question') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      const { question, options } = JSON.parse(body);
      displayQuestion(question, options);
      res.statusCode = 200;
      res.setHeader('Content-Type', 'text/plain');
      res.end('Question displayed\n');
    });
  } else {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Not Found\n');
  }
});

const PORT = process.env.PORT || 2900;

function displayQuestion(question, options) {
  const formattedOptions = options.map((option, index) => {
    const letter = String.fromCharCode(65 + index);
    return `${letter}. ${option}`;
  }).join('\n');

  // Escape quotes and backslashes for AppleScript
  const escapedQuestion = question.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  const escapedOptions = formattedOptions.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  
  const fullText = `${escapedQuestion}\n\n${escapedOptions}`;
  
  const availableOptions = options.map((_, index) => String.fromCharCode(65 + index));
  const optionsList = availableOptions.map(opt => `"${opt}"`).join(', ');

  // Use a simpler AppleScript approach without icons
  const script = `tell application "System Events" to choose from list {${optionsList}} with prompt "${fullText}" default items {"${availableOptions[0]}"} with title "Question"`;

  console.log(`Displaying question: ${question}`);
  console.log(`Available options: ${availableOptions.join(', ')}`);

  exec(`osascript -e '${script}'`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error displaying question: ${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`stderr: ${stderr}`);
      return;
    }
    const result = stdout.trim();
    if (result === 'false') {
      console.log('User cancelled the question');
    } else {
      console.log(`User selected: ${result}`);
    }
  });
}
function startServer() {
  if (!server.listening) {
    server.listen(PORT, () => {
      console.log(`Server running at http://localhost:${PORT}/`);
    });
  }
}

startServer();