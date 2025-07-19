const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL Connection Pool
const pool = new Pool({
  user: process.env.DB_USER || 'admin',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'dreamvacations',
  password: process.env.DB_PASSWORD || 'Oziegbe27',
  port: process.env.DB_PORT || 5432,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Test database connection on startup
pool.query('SELECT NOW()')
  .then(() => console.log('Database connection established'))
  .catch(err => {
    console.error('Database connection failed:', err);
    process.exit(1);
  });

// Create destinations table if not exists
const createTable = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS destinations (
        id SERIAL PRIMARY KEY,
        country VARCHAR(255) NOT NULL,
        capital VARCHAR(255),
        population BIGINT,
        region VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Destinations table ready');
  } catch (err) {
    console.error('Error creating table:', err);
    process.exit(1);
  }
};

// Initialize table on startup
createTable();

// Routes
app.get('/api/destinations', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM destinations ORDER BY id DESC');
    res.json(rows);
  } catch (err) {
    console.error('Error fetching destinations:', err);
    res.status(500).json({ error: 'Failed to fetch destinations' });
  }
});

app.post('/api/destinations', async (req, res) => {
  const { country } = req.body;
  
  if (!country) {
    return res.status(400).json({ error: 'Country name is required' });
  }

  try {
    const response = await axios.get(`${process.env.COUNTRIES_API_BASE_URL}/name/${encodeURIComponent(country)}`);
    const countryInfo = response.data[0];

    const { rows } = await pool.query(
      `INSERT INTO destinations (country, capital, population, region) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [
        country,
        countryInfo.capital?.[0] || 'N/A',
        countryInfo.population || 0,
        countryInfo.region || 'Unknown'
      ]
    );
    
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error('Error adding destination:', err);
    res.status(500).json({ 
      error: err.response?.statusText || 'Failed to add destination' 
    });
  }
});

app.delete('/api/destinations/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const { rowCount } = await pool.query(
      'DELETE FROM destinations WHERE id = $1',
      [id]
    );
    
    if (rowCount === 0) {
      return res.status(404).json({ error: 'Destination not found' });
    }
    
    res.status(204).end();
  } catch (err) {
    console.error('Error deleting destination:', err);
    res.status(500).json({ error: 'Failed to delete destination' });
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  pool.end()
    .then(() => {
      console.log('Pool has ended');
      process.exit(0);
    })
    .catch(err => {
      console.error('Error ending pool:', err);
      process.exit(1);
    });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});