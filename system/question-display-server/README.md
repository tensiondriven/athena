# Question Display Server

A Node.js HTTP server that displays questions in native macOS dialog boxes using AppleScript. Perfect for creating interactive quizzes, surveys, or educational tools that appear as system-level dialogs.

## Features

- 🖥️ **Native macOS Integration**: Questions appear as system dialog boxes
- 📝 **Multiple Question Types**: Support for true/false and multiple choice questions
- 🌐 **HTTP API**: Simple REST endpoint for sending questions
- 🧪 **Test Harness**: Built-in testing tools for validation
- ⚡ **Lightweight**: Minimal dependencies, easy to set up

## Prerequisites

- **Node.js** (version 12 or higher)
- **macOS** (required for AppleScript dialog display)
- **Terminal/Command Line** access

## Installation & Setup

1. **Clone or download** this project to your local machine

2. **Navigate** to the project directory:
   ```bash
   cd question-display-server
   ```

3. **Start the server**:
   ```bash
   node index.js
   ```
   
   You should see:
   ```
   Server running at http://localhost:3000/
   ```

## Quick Test

To verify everything is working, run our simple test harness:

```bash
# In a new terminal window (keep the server running)
node test-simple.js
```

This will send two test questions:
1. **True/False**: "Is the sky blue?" with options [True, False]
2. **Multiple Choice**: "What is 2 + 2?" with options [3, 4, 5, 6]

You should see native macOS dialog boxes appear on your screen!

## Usage Examples

### Basic Question Format

Send a POST request to `http://localhost:3000/display-question` with this JSON format:

```json
{
  "question": "Your question text here",
  "options": ["Option A", "Option B", "Option C", "Option D"]
}
```

### True/False Question Example

```bash
curl -X POST http://localhost:3000/display-question \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Is JavaScript a programming language?",
    "options": ["True", "False"]
  }'
```

### Multiple Choice Question Example

```bash
curl -X POST http://localhost:3000/display-question \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Which of these is a JavaScript framework?",
    "options": ["React", "Python", "MySQL", "CSS"]
  }'
```

### Using the Test Client

For more comprehensive testing, use the included test client:

```bash
# Send the original test questions (from test-questions.js)
node test-questions.js

# Send simple true/false and multiple choice tests
node test-simple.js
```

## API Documentation

### POST /display-question

Displays a question in a native macOS dialog box.

**Request Body:**
```json
{
  "question": "string (required) - The question text to display",
  "options": ["array of strings (required) - Answer options (2-4 items)"]
}
```

**Response:**
- **200 OK**: `Question displayed\n`
- **404 Not Found**: For any other endpoint

**Example Response:**
```
Question displayed
```

## How It Works

1. **Server receives** a POST request with question data
2. **AppleScript generates** a native macOS dialog with the question and options
3. **User sees** a system dialog box with multiple choice buttons (A, B, C, D)
4. **Server responds** with confirmation that the question was displayed

## File Structure

```
question-display-server/
├── index.js           # Main server file
├── test-questions.js  # Original test client with sample questions
├── test-simple.js     # Simple test harness (true/false + multiple choice)
└── README.md          # This documentation
```

## Troubleshooting

### Server Won't Start
- **Check port availability**: Make sure port 3000 isn't already in use
- **Try a different port**: Set `PORT=3001 node index.js`

### Questions Don't Appear
- **Verify macOS**: This only works on macOS due to AppleScript dependency
- **Check server logs**: Look for error messages in the terminal
- **Test connectivity**: Try `curl http://localhost:3000/display-question`

### Permission Issues
- **Allow Terminal access**: macOS may prompt for accessibility permissions
- **System Preferences**: Go to Security & Privacy → Accessibility → Allow Terminal

### Common Error Messages

**"Connection refused"**
- The server isn't running. Start it with `node index.js`

**"Error displaying question"**
- AppleScript execution failed. Check macOS permissions

**"Not Found"**
- Wrong endpoint. Use `/display-question` with POST method

## Development

### Adding New Question Types

To support new question formats, modify the `displayQuestion` function in [`index.js`](index.js):

```javascript
function displayQuestion(question, options) {
  // Customize the AppleScript dialog here
  // Current format supports A, B, C, D options
}
```

### Creating Custom Tests

Create new test files following the pattern in [`test-simple.js`](test-simple.js):

```javascript
const testQuestion = {
  question: "Your custom question?",
  options: ["Option 1", "Option 2"]
};

sendQuestion(testQuestion);
```

## License

This project is open source and available under the MIT License.

---

**Need help?** Check the troubleshooting section above or review the test files for working examples.