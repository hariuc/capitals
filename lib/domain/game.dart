import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:capitals/data/data.dart';
import 'package:capitals/domain/items.dart';

import 'models.dart';
import 'palette.dart';

class GameState {
  static const GameState empty = GameState(0, 1);

  final int score;
  final int topScore;

  const GameState(this.score, this.topScore);

  double get progress => max(0, score) / topScore;

  GameState copyWith({
    int? score,
    int? topScore,
  }) =>
      GameState(
        score ?? this.score,
        topScore ?? this.topScore,
      );
}

class GameLogic extends Cubit<GameState> {
  static const _successGuess = 3;
  static const _successFake = 1;
  static const _fail = -1;
  static const countryLimit = 30;

  final Random _random;
  final Api _api;
  final Assets _assets;
  final PaletteLogic _palette;
  final ItemsLogic _itemsLogic;

  GameLogic(
    this._random,
    this._api,
    this._assets,
    this._palette,
    this._itemsLogic,
  ) : super(GameState.empty);

  Future<void> onStartGame() async {
    try {
      var countries = await _api.fetchCountries();
      countries = _countryWithImages(countries);
      countries.shuffle(_random);
      countries = countries.sublist(0, countryLimit);
      _prepareItems(countries);
    } catch (e) {
      // TODO handle error
      print(e);
    }
    await _updatePalette();
  }

  Future<void> onReset() async {
    _updateScore(0);
    _updateTopScore(1);
    _itemsLogic.reset();
    _prepareItems(_itemsLogic.state.items.map((e) => e.original).toList());
  }

  Future<void> onGuess(int index, bool isTrue) async {
    final isActuallyTrue = _itemsLogic.state.isCurrentTrue;
    var scoreUpdate = 0;
    if (isTrue && isActuallyTrue) {
      scoreUpdate = _successGuess;
    }
    if (!isTrue && !isActuallyTrue) {
      scoreUpdate = _successFake;
    }
    if (isTrue && !isActuallyTrue || !isTrue && isActuallyTrue) {
      scoreUpdate = _fail;
    }
    _updateScore(state.score + scoreUpdate);
    _itemsLogic.updateCurrent(index);

    if (!_itemsLogic.state.isCompleted) {
      await _updatePalette();
    }
  }

  Future<void> _updatePalette() => _palette.updatePalette(
      _itemsLogic.state.current.image, _itemsLogic.state.next?.image);

  void _updateScore(int score) => emit(state.copyWith(score: score));

  void _updateTopScore(int topScore) =>
      emit(state.copyWith(topScore: topScore));

  void _prepareItems(List<Country> countries) {
    _itemsLogic.updateItems(countries);
    final originals = _itemsLogic.state.originalsLength;
    final fakes = _itemsLogic.state.fakeLength;
    final topScore = originals * _successGuess + fakes * _successFake;
    _updateTopScore(topScore);
  }

  List<Country> _countryWithImages(List<Country> countries) => countries
      .where((element) => element.capital.isNotEmpty)
      .map((e) {
        final imageUrls = _assets.capitalPictures(e.capital);
        if (imageUrls.isNotEmpty) {
          final randomIndex = _random.nextInt(imageUrls.length);
          return Country(e.name, e.capital,
              imageUrls: imageUrls, index: randomIndex);
        } else {
          return Country(e.name, e.capital, imageUrls: imageUrls, index: -1);
        }
      })
      .where((element) => element.index != -1)
      .toList();
}
