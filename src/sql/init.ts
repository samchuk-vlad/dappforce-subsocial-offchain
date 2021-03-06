import { readFileSync } from 'fs';
import { pg } from '../connections/connect-postgres';
import { postgesLog as log } from '../connections/loggers';

const ENV = process.env.NODE_ENV || 'development';
const buildPath = ENV === 'production' ? 'build/' : '';
const initSchema = readFileSync(buildPath + 'src/sql/initSchema.sql', 'utf8');
const initDb = readFileSync(buildPath + 'src/sql/initDb.sql', 'utf8');

pg.query(initSchema, (err: Error) => {
  if (err) throw err;
  pg.query(initDb, (err: Error) => {
    if (err) {
      log.error('Failed to initialize a database', err)
      throw err
    }
    log.info('Database inited');
  })
});
