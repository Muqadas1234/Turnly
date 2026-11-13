const pool = require('./config/db');
async function check() {
  const res = await pool.query(" SELECT column_name FROM information_schema.columns WHERE table_name = hospitals \);
 console.log(res.rows.map(r => r.column_name));
 await pool.end();
}
check();