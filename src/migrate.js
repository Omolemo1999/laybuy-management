require('dotenv').config();
const fs=require('fs'); const path=require('path'); const {Pool}=require('pg');
(async()=>{if(!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required'); const p=new Pool({connectionString:process.env.DATABASE_URL,ssl:process.env.DATABASE_SSL==='true'?{rejectUnauthorized:process.env.DATABASE_SSL_REJECT_UNAUTHORIZED!=='false'}:undefined}); try{await p.query(fs.readFileSync(path.join(__dirname,'../db/schema.sql'),'utf8')); console.log('Database schema is up to date.')}finally{await p.end()}})().catch(e=>{console.error(e.message);process.exit(1)});
