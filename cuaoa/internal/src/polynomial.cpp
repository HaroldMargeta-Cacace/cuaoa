/* Copyright 2024 Jonas Blenninger
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <vector>
#include <cstddef>        // for std::size_t
#include <map>            // or unordered_map if used
#include <algorithm>      // for std::copy or std::transform if used
#include "polynomial.hpp"

Polynomial makePolynomialsfromAdjacencyMatrix(const double *flat,
                                              std::size_t dimension) {
  std::map<std::size_t, double> polynomial;

  for (std::size_t i = 0; i < dimension; i++) {
    double contrib = 0.0;
    for (std::size_t j = 0; j < dimension; j++) {
      std::size_t index = i * dimension + j;
      double value = flat[index];

      bool hasValue = value != 0;
      contrib += value;

      if (i == j) {
        continue;
      }

      if (hasValue) {
        std::size_t key = (1 << i) + (1 << j);
        if (polynomial.count(key) > 0) {
          polynomial[key] += value;
        } else {
          polynomial[key] = +value;
        }
      }
    }

    size_t key = (1 << i);
    if (contrib != 0) {
      if (polynomial.count(key) > 0) {
        polynomial[key] -= contrib;
      } else {
        polynomial[key] = -contrib;
      }
    }
  }

  std::vector<std::size_t> keys;
  std::vector<double> vals;
  for (const auto& [k, v] : polynomial) {
      keys.push_back(k);
      vals.push_back(v);
  }

  Polynomial pols;
  pols.keys = std::vector<std::size_t>(keys.begin(), keys.end());
  pols.values = std::vector<double>(vals.begin(), vals.end());
  return pols;
}
