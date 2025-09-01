# R2R Deployment Guide - Post-Upgrade

## Pre-Deployment Checklist

### Environment Requirements
- [ ] Python 3.9+ installed
- [ ] PostgreSQL 14+ with vector extensions enabled
- [ ] Docker and Docker Compose (if using containerized deployment)
- [ ] Required Python packages installed (see requirements.txt)
- [ ] Environment variables configured

### Database Preparation
- [ ] PostgreSQL instance accessible
- [ ] pgvector extension installed: `CREATE EXTENSION IF NOT EXISTS vector;`
- [ ] HNSW extension available for vector indexing
- [ ] Database user has CREATE, SELECT, INSERT, UPDATE, DELETE permissions
- [ ] Connection pooling configured if using external pool

### Configuration Verification
- [ ] Verify R2R configuration file includes updated timeout settings
- [ ] Confirm user limits match production requirements
- [ ] Database connection string updated
- [ ] LLM provider configuration validated

## Deployment Steps

### Step 1: Database Migration
```bash
# Navigate to R2R directory
cd /opt/sectorflow/UPDATED_NEW_R2R

# Activate virtual environment
source .venv/bin/activate

# Run database migrations (if using Alembic)
python -m alembic upgrade head

# Or manual schema updates if needed
python -c "
import asyncio
from core.providers.database.base import PostgresConnectionManager
from core.providers.database.chunks import PostgresChunkProvider

async def setup():
    # Initialize connection manager and run setup
    pass  # Use your connection setup here
"
```

### Step 2: Dependency Installation
```bash
# Install/update core dependencies
pip install -r requirements.txt

# Install optional dependencies based on your setup
pip install supabase  # If using Supabase
pip install bcrypt PyNaCl  # For authentication
pip install mailersend  # If using MailerSend
```

### Step 3: Configuration Update
Update your R2R configuration file:

```yaml
# r2r.toml or configuration file
app:
  default_max_documents_per_user: 10000
  default_max_chunks_per_user: 100000000
  default_max_collections_per_user: 1000

completion:
  request_timeout: 800.0

database:
  postgres_configuration_settings:
    max_connections: 100
    statement_cache_size: 0  # Disable if using PgBouncer/Supabase
```

### Step 4: Service Restart
```bash
# If using systemd service
sudo systemctl restart r2r

# If using Docker Compose
docker-compose down
docker-compose up -d

# If running directly
python -m r2r serve
```

### Step 5: Verification
```bash
# Test basic functionality
python -c "
import asyncio
from r2r import R2RClient

async def test():
    client = R2RClient('http://localhost:7272')
    health = await client.health()
    print('Health check:', health)

asyncio.run(test())
"
```

## Rolling Deployment Strategy

### For Production Systems
1. **Deploy to staging environment first**
2. **Run full test suite on staging**
3. **Perform database backup before production deployment**
4. **Deploy during maintenance window**
5. **Monitor key metrics post-deployment**

### Zero-Downtime Deployment
```bash
# 1. Prepare new version in parallel environment
# 2. Update database schema (ensure backward compatibility)
# 3. Deploy new version to load balancer pool gradually
# 4. Monitor error rates and performance
# 5. Complete rollout or rollback if issues detected
```

## Post-Deployment Monitoring

### Key Metrics to Monitor
```bash
# Response time monitoring
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:7272/health"

# Database connection monitoring
SELECT count(*) FROM pg_stat_activity WHERE datname = 'your_r2r_db';

# Vector search performance
EXPLAIN ANALYZE SELECT * FROM chunks ORDER BY vec <-> '[0.1,0.2,0.3]'::vector LIMIT 10;
```

### Health Check Endpoints
- `GET /health` - Basic health status
- `GET /app_settings` - Configuration verification
- `GET /server_stats` - Performance metrics

### Log Monitoring
Monitor these log patterns:
- `Request timed out after 800.0 seconds` - LLM timeout issues
- `Database Configuration Error` - Connection/caching issues
- `Large object.*not found` - File operation errors
- `Failed to read large object` - File retrieval issues

## Rollback Procedures

### Quick Rollback
```bash
# If using Git for deployment
git checkout <previous-stable-commit>
docker-compose restart

# If using versioned deployments
./deploy.sh rollback --version=<previous-version>
```

### Database Rollback
```bash
# If database changes were made
python -m alembic downgrade -1  # Roll back one migration

# Or restore from backup
pg_restore -d your_r2r_db backup_file.sql
```

### Configuration Rollback
```bash
# Restore previous configuration
cp r2r.toml.backup r2r.toml
sudo systemctl restart r2r
```

## Troubleshooting Common Issues

### Connection Timeouts
**Symptom:** Database connection errors
**Solution:** 
- Verify PostgreSQL is accepting connections
- Check network connectivity
- Increase connection timeout if needed
- Verify connection pool settings

### LLM Request Timeouts
**Symptom:** Requests failing after 800 seconds
**Solution:**
- Check LLM provider status
- Verify network connectivity to LLM service
- Consider reducing request complexity
- Implement request batching

### File Operation Errors
**Symptom:** File upload/download failures
**Solution:**
- Check PostgreSQL large object permissions
- Verify disk space availability
- Monitor database connection pool
- Check file size limits

### Vector Search Performance
**Symptom:** Slow similarity searches
**Solution:**
- Verify HNSW index creation: `\d+ chunks_table_name`
- Check index usage: `EXPLAIN ANALYZE ...`
- Consider index parameters tuning
- Monitor memory usage

## Security Considerations

### Post-Deployment Security Review
- [ ] Verify database connections use SSL
- [ ] Confirm authentication mechanisms are working
- [ ] Check file upload restrictions are in place
- [ ] Validate user permission limits are enforced
- [ ] Review API endpoint access controls

### Monitoring for Security Issues
- Monitor failed authentication attempts
- Watch for unusual file upload patterns
- Track database query patterns
- Monitor for potential injection attempts

## Performance Optimization

### Database Optimization
```sql
-- Monitor slow queries
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Monitor connection pool
SELECT count(*), state FROM pg_stat_activity GROUP BY state;
```

### Application Optimization
- Monitor request/response times
- Track memory usage patterns
- Monitor CPU utilization
- Check disk I/O patterns

## Support and Maintenance

### Regular Maintenance Tasks
- Database vacuum and analyze
- Log rotation and cleanup
- Index maintenance and optimization
- Connection pool monitoring
- Performance metrics review

### Emergency Contacts
- Database Administrator: [Contact Info]
- System Administrator: [Contact Info]  
- Application Support: [Contact Info]
- Escalation Procedures: [Document Link]

## Additional Resources
- R2R Documentation: [Link to docs]
- PostgreSQL Performance Tuning: [Link]
- Vector Database Best Practices: [Link]
- Monitoring and Alerting Setup: [Link]