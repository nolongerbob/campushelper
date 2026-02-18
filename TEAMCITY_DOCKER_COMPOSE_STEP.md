# Шаг Docker Compose в TeamCity — чтобы билд не падал по порту 45454

## Проблема
Ошибка: `Bind for 0.0.0.0:45454 failed: port is already allocated`

## Решение 1 (рекомендуется): использовать docker-compose.ci.yml
В шаге **"Docker Compose"** в поле **Compose file** укажи: **`docker-compose.ci.yml`**  
В этом файле порт не пробрасывается — билд будет проходить из любой ветки.

## Решение 2: чтобы в feature было как в main
В корне репозитория теперь один **docker-compose.yml без порта** (как в main).  
Чтобы так же было в feature:
```bash
git checkout feature
git merge main
git push origin feature
```
После этого сборка из feature будет использовать тот же docker-compose.yml без порта.
