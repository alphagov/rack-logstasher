# 2.0.0

- Add support for Rack 3
- **BREAKING** Only allows lower case header keys due to [underlying Rack spec change at 3.0.0beta1](https://github.com/rack/rack/blob/main/CHANGELOG.md#300beta1---2022-08-08).

# 1.1.0

- Require Ruby 2.7 and greater

# 1.0.2

- Fix logging error where Rack uses the system monotonic clock.

# 1.0.1

- *Changes logging format* to drop the "@fields" prefix and rename "@tags" to "tags".
- Updates development dependencies

# 1.0.0

- Add support for Rack 2 (thanks @anicholson https://github.com/alphagov/rack-logstasher/issues/5)
- Drop support for Rack < 2
