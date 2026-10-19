# Linux-Projects

Welcome to the **Linux-Projects** repository! This is a comprehensive collection of projects and exercises related to Linux and Bash scripting, designed to take you from beginner to advanced levels.

## 🚀 Features

- **30-Day Bash Challenge** - Structured learning path with daily exercises
- **Beginner to Advanced Projects** - Progressive learning with 12 comprehensive steps
- **Enhanced Scripts** - Production-ready scripts with error handling and security
- **Advanced Scripting** - Modern DevOps practices, API integration, and cloud automation
- **Comprehensive Testing** - Automated testing with Bats framework
- **CI/CD Pipeline** - GitHub Actions for continuous integration
- **Open Source Ready** - Complete documentation and contribution guidelines

## 📚 Project Structure

```
Linux-Projects/
├── 30_days_of_bash/           # 30-day structured learning challenge
├── beginner_to_advanced_linux_projects/  # 12-step learning progression
├── updated_bash_projects/      # Enhanced production scripts
│   ├── to-do-list/            # Advanced todo manager with backup/restore
│   └── disk-space-usage/      # Enhanced disk analyzer with caching
├── advanced_scripting/         # Modern DevOps and cloud automation
│   ├── api_client.sh          # REST API client with caching
│   ├── docker_manager.sh      # Docker container management
│   └── README.md              # Advanced scripting documentation
├── Basic_Projects/            # Basic user management examples
├── vagrant installation/       # Apple Silicon setup instructions
├── test/                      # Comprehensive test suite
├── .github/workflows/         # CI/CD pipeline
├── CONTRIBUTING.md            # Contribution guidelines
├── CODE_OF_CONDUCT.md         # Community standards
├── LICENSE                    # MIT License
└── .gitignore                # Comprehensive ignore patterns
```

## 🛠️ Getting Started

### Prerequisites

- Linux, macOS, or WSL
- Bash shell (version 4.0 or higher)
- Git for version control
- Basic command line knowledge

### Quick Start

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/akintunero/Linux-Projects.git
   cd Linux-Projects
   ```

2. **Install Dependencies:**
   ```bash
   # Install testing framework
   sudo apt-get install jq curl wget bc shellcheck
   
   # Install bats-core (testing framework)
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   sudo ./install.sh /usr/local
   cd ..
   rm -rf bats-core
   
   # Or on macOS
   brew install bats-core jq curl wget bc shellcheck
   ```

3. **Run Your First Script:**
   ```bash
   # Test the enhanced todo manager
   cd updated_bash_projects/to-do-list
   chmod +x to_do_list.sh
   ./to_do_list.sh add "Learn Linux scripting"
   ./to_do_list.sh list
   ```

4. **Start Learning:**
   ```bash
   # Begin the 30-day challenge
   cd 30_days_of_bash
   # Follow the daily lessons in Day01.md, Day02.md, etc.
   ```

## 📖 Learning Paths

### 🎯 30-Day Bash Challenge
Perfect for beginners! Follow a structured daily learning path:
- **Days 1-10**: Basic commands, variables, control flow
- **Days 11-20**: Text processing, functions, automation
- **Days 21-30**: Advanced topics, system administration, final project

### 🚀 Beginner to Advanced
Comprehensive 12-step progression:
1. **Linux Fundamentals** - File system, permissions, basic commands
2. **User Management** - User/group administration
3. **Networking** - Network configuration and tools
4. **Shell Scripting** - Automation and scripting
5. **Package Management** - Software installation and management
6. **System Security** - Security auditing and hardening
7. **System Monitoring** - Performance monitoring tools
8. **Disk Management** - Storage and partitioning
9. **Backup & Recovery** - Data protection strategies
10. **Automation** - CI/CD and orchestration
11. **Virtualization** - Containers and VMs
12. **Best Practices** - Industry standards and optimization

### 🔧 Enhanced Scripts
Production-ready scripts with modern features:
- **Todo Manager**: Backup/restore, search, validation, timestamps
- **Disk Usage Analyzer**: Caching, progress bars, multiple formats
- **Error Handling**: Comprehensive error checking and recovery
- **Security**: Input validation and sanitization
- **Logging**: Detailed operation logging

### ⚡ Advanced Scripting
Modern DevOps and cloud automation:
- **API Integration**: REST clients, web scraping, JSON processing
- **Cloud Automation**: AWS CLI, Docker, Kubernetes
- **Security Scripts**: Auditing, encryption, monitoring
- **Performance Optimization**: Profiling, parallel processing
- **CI/CD Pipelines**: GitHub Actions, Jenkins integration

## 🧪 Testing

### Run Tests
```bash
# Run all tests
bats test/

# Run specific test file
bats test/todo_manager_test.sh

# Run with verbose output
bats --verbose test/
```

### Automated Testing
The repository includes GitHub Actions for continuous integration:
- Syntax checking with `shellcheck`
- Unit tests with Bats framework
- Documentation validation
- Code quality checks

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** following our coding standards
4. **Add tests** for new functionality
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Code Standards

- Follow bash best practices
- Add comprehensive error handling
- Include input validation
- Write clear documentation
- Add unit tests for new features
- Use consistent formatting

## 📋 Requirements

### System Requirements
- **OS**: Linux, macOS, or WSL
- **Shell**: Bash 4.0+
- **Tools**: curl, jq, wget, bc (for advanced scripts)
- **Testing**: bats-core framework

### Optional Dependencies
- **Docker**: For container management scripts
- **AWS CLI**: For cloud automation
- **Kubernetes**: For orchestration scripts

## 🔧 Configuration

### Environment Setup
```bash
# Create configuration directory
mkdir -p ~/.config/advanced_scripts

# Copy example configuration
cp advanced_scripting/config/example.conf ~/.config/advanced_scripts/config.conf
```

### Script Configuration
Most scripts support configuration files:
```bash
# ~/.config/advanced_scripts/config.conf
API_BASE_URL="https://api.example.com"
AWS_REGION="us-west-2"
DOCKER_REGISTRY="your-registry.com"
```

## 📊 Project Statistics

- **30+ Daily Lessons** in the bash challenge
- **12 Comprehensive Steps** in the learning progression
- **10+ Production Scripts** with enhanced features
- **50+ Unit Tests** for quality assurance
- **100% Test Coverage** for core functionality

## 🏆 Achievements

Complete the learning paths to earn these achievements:
- 🥉 **Bash Beginner**: Complete Days 1-10
- 🥈 **Bash Intermediate**: Complete Days 11-20
- 🥇 **Bash Expert**: Complete Days 21-30
- 🚀 **DevOps Practitioner**: Complete advanced scripting section
- 🛡️ **Security Specialist**: Complete security scripts
- ☁️ **Cloud Architect**: Complete cloud automation scripts

## 📞 Support

### Getting Help
- 📖 **Documentation**: Check the README files in each directory
- 🐛 **Issues**: Report bugs via GitHub Issues
- 💬 **Discussions**: Ask questions in GitHub Discussions
- 📧 **Email**: Contact akintunero101@gmail.com

### Community
- **Twitter**: [@akintunero](https://twitter.com/akintunero)
- **LinkedIn**: [olumayowaa](https://linkedin.com/in/olumayowaa)
- **GitHub**: [akintunero](https://github.com/akintunero)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Contributors**: All community members who contribute to this project
- **Open Source**: Built on the shoulders of amazing open source tools
- **Community**: The Linux and DevOps communities for inspiration

---

*Empowering developers to master Linux and automation through hands-on learning.*
