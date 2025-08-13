# RouteMate Backend API

This is the FastAPI backend service for the RouteMate transportation app.

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- pip (Python package installer)

### Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/dewminawijekoon/RouteMate.git
   cd RouteMate/backend
   ```

2. **Create a virtual environment**:
   ```bash
   # Windows
   python -m venv .venv
   .venv\Scripts\activate

   # macOS/Linux
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the development server**:
   ```bash
   fastapi dev main.py
   ```

   The API will be available at:
   - **API**: http://localhost:8000
   - **Interactive API docs**: http://localhost:8000/docs
   - **Alternative docs**: http://localhost:8000/redoc

## 📁 Project Structure

```
backend/
├── main.py              # FastAPI application entry point
├── README.md           # This file
├── requirements.txt    # Python dependencies 
└── .venv/             # Virtual environment (ignored by git)
```

## 🛠️ Development Setup

### Setting up the environment

1. **Activate the virtual environment**:
   ```bash
   # Windows
   .venv\Scripts\activate

   # macOS/Linux
   source .venv/bin/activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Install additional development dependencies** (optional):
   ```bash
   pip install pytest pytest-asyncio httpx
   ```

4. **Update requirements.txt** (if you add new dependencies):
   ```bash
   pip freeze > requirements.txt
   ```

### Running the server

For development with auto-reload:
```bash
fastapi dev main.py
```
