## For Reduct Store Docker
docker run -p 8383:8383 -v ${PWD}/data:/data reduct/store:latest

curl http://127.0.0.1:8383/api/v1/info

cargo watch -q -c -w src/ -x run

cargo watch -q -c -w tests/ -x "test -q quick_dev -- --nocapture"