"""Configuration settings for the application."""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings."""
    
    # Database
    DATABASE_URL: str
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/1"
    
    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    
    # Service Token (for internal endpoints)
    SERVICE_TOKEN: Optional[str] = None
    
    # Mock Mode
    MOCK_MODE: bool = False
    MOCK_DATA_PATH: str = "/app/mock-data"
    
    # Anthropic (LLM)
    ANTHROPIC_API_KEY: Optional[str] = None
    
    # Secrets Encryption
    SECRETS_MASTER_KEY: Optional[str] = None
    SECRETS_SALT: Optional[str] = None
    
    # API Info
    API_VERSION: str = "1.0.0"
    API_TITLE: str = "MSP Analytics API"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
