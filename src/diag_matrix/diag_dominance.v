module diag_matrix

import vtl
import arrays
import math

fn (tnsr &vtl.Tensor<f64>) get_row(i int) &vtl.Tensor<f64> {
	return tnsr.slice([i, i + 1], [0, tnsr.shape[1]])
}

fn (tnsr &vtl.Tensor<f64>) product(vec &vtl.Tensor<f64>) &vtl.Tensor<f64> {
	mut res := []f64{}
	col := vec.to_array()
	for i in 0 .. vec.shape[0] {
		row := tnsr.get_row(i).to_array()
		multiplies := arrays.group<f64>(row, col).map(it[0] * it[1])
		res << arrays.reduce(multiplies, fn (s f64, el f64) f64 {
			return s + el
		}) or { 0.0 }
	}
	return vtl.from_1d(res)
}

fn (tnsr &vtl.Tensor<f64>) print() string {
	mut str := ''
	if tnsr.is_matrix() {
		mut cols := []string{}
		for i in 0 .. tnsr.shape[0] {
			mut row := []f64{}
			for j in 0 .. tnsr.shape[1] {
				row << tnsr.get([i, j])
			}
			cols << '[' + row.map('${it:.5}').join(', ') + ']'
		}
		str = '[' + cols.join(',\n') + ']'
	} else {
		mut row := []f64{}
		for i in 0 .. tnsr.shape[0] {
			row << tnsr.get([i, 0])
		}
		str = '[' + row.map('${it:.5}').join(',\n') + ']'
	}
	return str
}

fn max<T>(first T, second T) T {
	return if first > second { first } else { second }
}

fn min<T>(first T, second T) T {
	return if first < second { first } else { second }
}

struct OrderNum {
	num   f64
	order int
}

fn sum_array(arr []f64, digits []bool) f64 {
	mut res := 0.0
	for i, el in arr {
		res += if digits[i] { -el } else { el }
	}
	return res
}

fn swap<T>(arr []T, i1 int, i2 int) []T {
	mut c := arr.clone()
	f := c[i1]
	c[i1] = c[i2]
	c[i2] = f
	return c
}

fn solve_module_inequation(row1 []f64, row2 []f64, i_first int) f64 {
	arr := swap(arrays.group<f64>(row1, row2), 0, i_first)
	mut upper_bounds := arr.filter(it[1] >= 0).map(OrderNum{
		num: it[0] / it[1]
		order: arr.index(it)
	})
	mut lower_bounds := arr.filter(it[1] < 0).map(OrderNum{
		num: it[0] / it[1]
		order: arr.index(it)
	})
	upper_bounds.sort(a.num < b.num)
	lower_bounds.sort(a.num > b.num)
	for i, upper_ord in upper_bounds {
		mut digits := []bool{len: arr.len, init: true}
		digits[0] = !digits[0]
		for k in 0 .. i {
			digits[upper_bounds[k].order] = !digits[upper_bounds[k].order]
		}
		sum1 := sum_array(arr.map(it[0]), digits)
		sum2 := sum_array(arr.map(it[1]), digits)
		alph_bound := sum1 / sum2
		mut lower := if lower_bounds.len > 0 { lower_bounds[0].num } else { math.inf(-1) }
		mut upper := upper_ord.num
		if sum2 < 0 {
			lower = max(lower, alph_bound)
		} else {
			upper = min(upper, alph_bound)
		}
		if i > 0 {
			lower = max(lower, upper_bounds[i - 1].num)
		}
		if lower < upper {
			if math.is_inf(lower, -1) {
				lower = upper - 1
			}
			return (lower + upper) / 2
		}
	}
	return 0.0
}

fn to_diag_dominance(mtrx &vtl.Tensor<f64>, vec &vtl.Tensor<f64>) ?(&vtl.Tensor<f64>, &vtl.Tensor<f64>, string) {
	mut altered_mtrx := [][]f64{}
	mut altered_vec := []f64{}
	if mtrx.shape[0] != mtrx.shape[1] && vec.shape[0] != mtrx.shape[0] {
		return error('Error, matrix is not symmetric, or dimenstion of vector and matrix are not equal')
	}
	mut logs := ''
	for m in 0 .. mtrx.shape[0] {
		for i in 0 .. mtrx.shape[0] {
			if i == m {
				continue
			}
			row1 := mtrx.get_row(m)
			row2 := mtrx.get_row(i)
			coef := solve_module_inequation(row1.to_array(), row2.to_array(), m)
			if coef != 0 {
				altered_mtrx << vtl.substract(row1, vtl.multiply_scalar(row2, coef)).to_array()
				altered_vec << vec.get([m, 0]) - coef * vec.get([i, 0])

				mut to_print := altered_mtrx.clone()
				to_print << arrays.chunk(mtrx.to_array(), mtrx.shape[0])[m + 1..]
				logs += vtl.from_2d(to_print).print() + '\n'
				logs += '${m + 1}-th row and ${i + 1}-th row:\n'
				logs += '$row1.to_array() - $coef * $row2.to_array()' + '\n;\n'
				break
			}
		}
	}
	if altered_mtrx.len == 0 {
		return error('This matrix could not be turnet into diagonal dominant form')
	}
	return vtl.from_2d(altered_mtrx), vtl.from_1d(altered_vec), logs
}

pub fn get_result(matrix [][]f64, vector []f64) ?(string, string, []string) {
	mtrx := vtl.from_2d(matrix)
	vec := vtl.from_1d(vector)
	transormed_m, transormed_v, logs := to_diag_dominance(mtrx, vec) or { return err }
	splited := logs.split('\n;\n')
	return transormed_m.print(), transormed_v.print(), splited[..splited.len - 1]
}
