# R2R API Changes - Upgrade from 3a2405c to Latest

## Overview
This document outlines the changes made during the R2R upgrade from commit 3a2405c6846388f228ef28998516e4102093ed83 to the latest version, focusing on preserved custom modifications and their impact on client applications.

## Configuration Changes

### User Limits (Production Scale)
**File:** `py/core/base/providers/base.py`
**Changes:**
- `default_max_documents_per_user`: Increased from 100 to 10,000
- `default_max_chunks_per_user`: Increased from 1,000,000 to 100,000,000  
- `default_max_collections_per_user`: Increased from 100 to 1,000

**Client Impact:** 
- Applications can now handle significantly larger document collections per user
- Existing rate limiting may need adjustment
- Monitor storage and processing capacity for increased limits

### Request Timeout Configuration
**File:** `py/core/base/providers/llm.py`
**Changes:**
- `request_timeout`: Increased from default to 800.0 seconds

**Client Impact:**
- Long-running LLM requests will now timeout after 800 seconds instead of default timeout
- Client applications should handle longer response times
- Consider implementing progress indicators for extended operations

### Database Connection Timeout
**File:** `py/core/providers/database/base.py`
**Changes:**
- `connect_timeout`: Set to 120 seconds in asyncpg pool creation

**Client Impact:**
- Database connection establishment may take up to 120 seconds
- Applications should implement appropriate connection retry logic
- Consider connection pooling for high-frequency operations

## Performance Enhancements

### Vector Index Optimization
**File:** `py/core/providers/database/chunks.py`
**Changes:**
- Added HNSW vector index: `CREATE INDEX IF NOT EXISTS idx_vectors_vec_hnsw ON {table} USING hnsw (vec vector_cosine_ops)`

**Client Impact:**
- Significantly improved vector similarity search performance
- Existing queries will automatically benefit from faster execution
- No client-side changes required

## Error Handling Improvements

### File Operations
**File:** `py/core/providers/file/postgres.py`
**Changes:**
- Enhanced error handling in PostgreSQL file operations
- Improved large object cleanup in failure scenarios
- Better exception handling for undefined object errors

**Client Impact:**
- More robust file upload/download operations
- Clearer error messages for file-related failures
- Reduced risk of orphaned large objects in database

## Architectural Improvements (Inherited from Latest R2R)

The following improvements were automatically inherited by upgrading to the latest R2R version:

### Enhanced Provider System
- Improved provider configuration and validation
- Better separation of concerns between different provider types
- More flexible configuration options

### Database Schema Evolution
- Updated table structures for better performance
- Improved indexing strategies
- Better support for concurrent operations

### API Standardization
- Consistent error response formats
- Improved request/response validation
- Better OpenAPI documentation

## Breaking Changes
**None identified** - All changes maintain backward compatibility with existing client applications.

## Recommended Client Updates

### 1. Timeout Handling
```python
# Recommended: Implement longer timeout handling for LLM requests
import asyncio

async def call_llm_with_timeout():
    try:
        response = await r2r_client.rag(
            query="your query",
            timeout=850  # Slightly higher than server timeout
        )
    except asyncio.TimeoutError:
        # Handle timeout gracefully
        pass
```

### 2. Error Handling
```python
# Recommended: Enhanced error handling for file operations
try:
    result = await r2r_client.upload_file(file_data)
except R2RException as e:
    if e.status_code == 404:
        # Handle file not found
        pass
    elif e.status_code == 500:
        # Handle server errors
        pass
```

### 3. Connection Management
```python
# Recommended: Implement connection retry logic
import asyncio

async def connect_with_retry(max_retries=3):
    for attempt in range(max_retries):
        try:
            await r2r_client.connect()
            break
        except ConnectionError:
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
```

## Testing Recommendations

### Performance Testing
- Test vector similarity searches with large datasets to verify HNSW index performance
- Validate timeout behavior with long-running operations
- Test file upload/download operations with various file sizes

### Load Testing
- Verify system behavior with increased user limits
- Test concurrent operations under new configuration parameters
- Monitor database connection pool behavior under load

### Error Scenario Testing
- Test file operation failures and cleanup
- Verify timeout handling in client applications
- Test database connection failures and recovery

## Monitoring Recommendations

### Key Metrics to Monitor
- Average response times for LLM requests (should be under 800s)
- Database connection pool utilization
- File operation success/failure rates
- Vector search query performance

### Alerts to Configure
- LLM request timeouts approaching 800s threshold
- Database connection failures
- File operation errors
- Vector index performance degradation

## Support Notes

For issues related to these changes:
1. Check timeout configurations if experiencing request failures
2. Verify database connectivity and pool settings for connection issues
3. Monitor file operation logs for large object handling errors
4. Review vector search performance if query speeds degrade

## Version Compatibility
- **Minimum Client SDK Version:** No changes required
- **Database Schema:** Automatically updated via migrations
- **API Version:** Maintains full backward compatibility