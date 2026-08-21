const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

const JWT_SECRET = 'secret'; // deliberately weak, matches lab pattern

// 1. Login endpoint - issues a normal "student" token
app.post('/login', (req, res) => {
  const username = req.body.username || 'student';
  const token = jwt.sign(
    { sub: 1, username, role: 'student' },
    JWT_SECRET
    // no expiry - intentional, matches lab pattern
  );
  res.json({ token });
});

// 2. VULNERABLE: /validate trusts client-supplied user_id instead of verified token claims
app.post('/validate', (req, res) => {
  try {
    const token = req.headers.authorization.split(' ')[1];
    jwt.verify(token, JWT_SECRET); // only checks token is validly signed - doesn't use its claims below

    const requestedId = req.body.user_id; // <- trusts client input (THE FLAW)
    // Should have used verified token claims instead

    res.json({
      valid: true,
      identity: {
        id: requestedId,
        role: requestedId == 2 ? 'admin' : 'student'
      }
    });
  } catch (err) {
    res.status(401).json({ error: 'invalid' });
  }
});

// 3. Admin-only protected resource
app.get('/admin/dashboard', (req, res) => {
  res.json({ message: 'Welcome to the admin dashboard' });
});

app.listen(3002, () => console.log('Broken auth service running on http://localhost:3002'));
